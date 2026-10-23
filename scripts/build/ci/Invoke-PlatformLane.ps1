[CmdletBinding()]
param(
    [string]$LaneId,
    [string]$ExpectedPowerShellVersion,
    [string]$ProvisioningFile,
    [string]$ModuleRoot,
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
)

. (Join-Path $PSScriptRoot 'CiLaneEnvironment.ps1')
. (Join-Path $PSScriptRoot 'CiTestResultSummary.ps1')
. (Join-Path $PSScriptRoot 'CiLaneManifest.ps1')
. (Join-Path $PSScriptRoot 'CiRuntimeEvidence.ps1')
. (Join-Path $PSScriptRoot 'CiDependencyRoot.ps1')
. (Join-Path $PSScriptRoot 'CiTestDetail.ps1')

function Get-CiLaneDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LaneId
    )

    $lane = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'CiLanes.json') -Raw | ConvertFrom-Json).lanes |
            Where-Object {$_.id -eq $LaneId}
    if (-not $lane) {
        throw "Unknown lane '$LaneId'."
    }

    return $lane
}

function Invoke-CiLanePhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$LogPath,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        $Context
    )

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $launch = Get-CiPhaseContext -Name $Name -LogPath $LogPath -Context $Context
    $launch.WorkingDirectory = $WorkingDirectory
    $launch.Command = $Command
    $contextFile = "$LogPath.context.json"
    $launch | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $contextFile
    & $launch.Expected.Executable -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Invoke-CiPhaseProcess.ps1') -ContextFile $contextFile 2>&1 |
            Tee-Object -FilePath $LogPath | Out-Host
    $exitCode = $LASTEXITCODE
    $runtime = if (Test-Path -LiteralPath $launch.RuntimePath) { Get-Content -LiteralPath $launch.RuntimePath -Raw | ConvertFrom-Json }

    return [pscustomobject][ordered]@{
        Name = $Name
        ExitCode = $exitCode
        DurationSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 1)
        LogFile = Split-Path -Leaf $LogPath
        RuntimeFile = Split-Path -Leaf $launch.RuntimePath
        TestRuntimeFile = Split-Path -Leaf $launch.TestRuntimePath
        Environment = $runtime.Environment
        Executable = $runtime.Executable
        ProcessId = $runtime.ProcessId
    }
}

function Get-CiPhaseContext {
    param([string]$Name, [string]$LogPath, $Context)

    if (-not $Context) {
        $actual = Get-CiRuntimeRecord
        $Context = @{ Expected = @{ OperatingSystem = $actual.Environment.OperatingSystem; Architecture = $actual.Environment.ProcessArchitecture; PowerShellVersion = $actual.Environment.PowerShellVersion; PowerShellChannel = 'stable'; Executable = $actual.Executable }; Identity = @{} }
    }
    $identity = @{} + $Context.Identity
    $identity.phase = $Name
    return @{ Expected = $Context.Expected; Identity = $identity; RuntimePath = "$LogPath.runtime.json"; TestRuntimePath = "$LogPath.test-runtime.json" }
}

function Get-CiModuleVersion {
    [CmdletBinding()]
    param()

    $module = @{}
    foreach ($name in 'Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet', 'Microsoft.PowerShell.PlatyPS') {
        $module[$name] = @(Get-Module -ListAvailable -Name $name | Sort-Object Version -Descending |
                Select-Object -First 1 | ForEach-Object {$_.Version.ToString()})
    }

    return $module
}

function Get-CiLanePhaseDefinition {
    [CmdletBinding()]
    param()

    return @(
        @{Name = 'build'; Command = 'Import-Module Pester -RequiredVersion 5.7.1; Import-Module NovaModuleTools -ErrorAction Stop; Invoke-NovaBuild'}
        @{Name = 'unit'; Command = 'Import-Module Pester -RequiredVersion 5.7.1; Import-Module NovaModuleTools -ErrorAction Stop; Invoke-NovaTest -OutputVerbosity Detailed -OutputRenderMode Ansi'}
        @{Name = 'integration'; Command = 'Import-Module Pester -RequiredVersion 5.7.1; Import-Module NovaModuleTools -ErrorAction Stop; Test-NovaBuild -OutputVerbosity Detailed -OutputRenderMode Ansi'}
    )
}

function Invoke-CiLanePhaseSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$LogDirectory,
        [Parameter(Mandatory)]$Context
    )

    $result = @()
    foreach ($definition in Get-CiLanePhaseDefinition) {
        $log = Join-Path $LogDirectory "$( $definition.Name ).log"
        $result += Invoke-CiLanePhase -Name $definition.Name -Command $definition.Command -LogPath $log -WorkingDirectory $RepositoryRoot -Context $Context
        if ($result[-1].ExitCode -ne 0) {
            break
        }
    }

    return $result
}

function Copy-CiTestResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    $summary = @{}
    $source = [ordered]@{
        unit = @('artifacts/UnitTestResults.xml', 'unit-nunit.xml')
        integration = @('artifacts/TestResults.xml', 'integration-nunit.xml')
    }
    foreach ($key in $source.Keys) {
        $path = Join-Path $RepositoryRoot $source[$key][0]
        if (Test-Path -LiteralPath $path) {
            Copy-Item -LiteralPath $path -Destination (Join-Path $OutputDirectory $source[$key][1])
            $summary[$key] = Get-CiTestResultSummary -Path $path
            $log = Join-Path $OutputDirectory "logs/$key.log"
            $detail = @(Read-CiTestDetail -Path $log)
            Assert-CiTestDetail -Summary $summary[$key] -Detail $detail -OperatingSystem (Get-CiLaneOperatingSystem)
            $detail | ConvertTo-Json -Depth 4 -AsArray | Set-Content -LiteralPath (Join-Path $OutputDirectory "$key-details.json")
            $summary[$key].SkippedName = @($detail | Where-Object Result -eq 'Skipped' | ForEach-Object { "$($_.File): $($_.Name)" })
        }
    }

    return $summary
}

function Write-CiLaneSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest
    )

    $line = @("### $( $Manifest.laneId ): $( $Manifest.status )", '')
    $line += $Manifest.mismatches | ForEach-Object {"- Environment mismatch: $_"}
    $line += $Manifest.phases | ForEach-Object {"- $( $_.Name ): exit code $( $_.ExitCode ), $( $_.DurationSeconds )s"}
    foreach ($key in $Manifest.tests.Keys) {
        $test = $Manifest.tests[$key]
        $line += "- $key tests: $( $test.Passed ) passed, $( $test.Failed ) failed, $( $test.Skipped ) skipped"
        $line += $test.SkippedName | ForEach-Object {"  - skipped (see test source and logs for the reason): $_"}
        if ($test.Skipped -gt 0 -and @($test.SkippedName).Count -eq 0) {
            $line += "  - skipped tests are not named in the report; see logs/*.log ([!] lines) and the test source for the reason"
        }
    }
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value $line
    }
    $line | Out-Host
}

function Get-CiLaneIdentity {
    param([string]$LaneId)

    $identity = @{ laneId = $LaneId; executionId = [guid]::NewGuid().ToString('N') }
    $defaults = @{ commitSha = @('GITHUB_SHA', 'local'); runId = @('GITHUB_RUN_ID', 'local'); runAttempt = @('GITHUB_RUN_ATTEMPT', '1') }
    foreach ($name in $defaults.Keys) {
        $value = [Environment]::GetEnvironmentVariable($defaults[$name][0])
        $identity[$name] = if ($value) { $value } else { $defaults[$name][1] }
    }
    return $identity
}

function Get-CiLaneRun {
    param([string]$LaneId, [string]$Version, [string]$RepositoryRoot, [string]$ProvisioningFile)

    $lane = Get-CiLaneDefinition -LaneId $LaneId
    $actual = Get-CiLaneEnvironment
    if (-not $Version) { $Version = $actual.PowerShellVersion }
    $expected = @{ OperatingSystem = $lane.os; Architecture = $lane.architecture; PowerShellChannel = $lane.powershell; PowerShellVersion = $Version; Executable = (Get-Process -Id $PID).Path }
    $output = Join-Path $RepositoryRoot "artifacts/ci/$LaneId"
    return @{
        Lane = $lane; Actual = $actual; Expected = $expected
        Identity = Get-CiLaneIdentity -LaneId $LaneId
        RepositoryRoot = $RepositoryRoot; Output = $output; Logs = Join-Path $output 'logs'
        ProvisioningFile = $ProvisioningFile; Provisioning = $null
        Phase = @(); Summary = @(); Mismatch = @()
    }
}

function Initialize-CiLaneArtifact {
    param([Parameter(Mandatory)][hashtable]$Run)

    if (Test-Path -LiteralPath $Run.Output) { Remove-Item -LiteralPath $Run.Output -Recurse -Force }
    New-Item -ItemType Directory -Path $Run.Logs -Force | Out-Null
    foreach ($report in 'UnitTestResults.xml', 'TestResults.xml') {
        Remove-Item -LiteralPath (Join-Path $Run.RepositoryRoot "artifacts/$report") -Force -ErrorAction SilentlyContinue
    }
    $PSVersionTable | Out-String | Set-Content -LiteralPath (Join-Path $Run.Output 'PSVersionTable.txt')
}

function Assert-CiLaneProvisioning {
    param([Parameter(Mandatory)][hashtable]$Run)

    if (-not $Run.ProvisioningFile) { return }
    $Run.Provisioning = Get-Content -LiteralPath $Run.ProvisioningFile -Raw -ErrorAction Stop | ConvertFrom-Json
    Assert-CiRuntimeRecord -Record $Run.Provisioning.runtime -Expected $Run.Expected
    if ($Run.Provisioning.runtimeIdentifier -ne $Run.Lane.runtimeIdentifier) { throw 'Provisioned runtime identifier differs from lane.' }
    if ($Run.Provisioning.version -ne $Run.Expected.PowerShellVersion) { throw 'Provisioned version differs from selected runtime.' }
}

function Invoke-CiLaneExecution {
    param([Parameter(Mandatory)][hashtable]$Run)

    $Run.Summary = @{}
    $Run.Mismatch = @(Test-CiLaneEnvironment -Expected $Run.Expected -Actual $Run.Actual -RequireGitHubHosted:([bool]$env:GITHUB_ACTIONS))
    if ($Run.Mismatch.Count -gt 0) { return }
    try {
        Assert-CiLaneProvisioning -Run $Run
        $Run.Phase = Invoke-CiLanePhaseSet -RepositoryRoot $Run.RepositoryRoot -LogDirectory $Run.Logs -Context @{ Expected = $Run.Expected; Identity = $Run.Identity }
        $Run.Summary = Copy-CiTestResult -RepositoryRoot $Run.RepositoryRoot -OutputDirectory $Run.Output
        Assert-CiLaneRuntimeEvidence -Directory $Run.Logs -Phase $Run.Phase -Expected $Run.Expected -Identity $Run.Identity
    } catch {
        $Run.Mismatch += $_.Exception.Message
    }
}

function Write-CiLaneManifest {
    param([Parameter(Mandatory)][hashtable]$Run)

    $manifest = Build-CiLaneManifest -LaneId $Run.Lane.id -CommitSha $Run.Identity.commitSha -Environment $Run.Actual -Mismatch $Run.Mismatch -Phase $Run.Phase -Summary $Run.Summary -Module (Get-CiModuleVersion)
    $manifest.schemaVersion = 1
    $manifest.configuration = $Run.Lane
    $manifest.selectedRuntime = $Run.Expected
    $manifest.identity = $Run.Identity
    $manifest.provisioning = $Run.Provisioning
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $Run.Output 'lane-manifest.json')
    Write-CiLaneSummary -Manifest $manifest
    return $manifest.status
}

function Invoke-CiLane {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LaneId, [string]$ExpectedPowerShellVersion, [string]$ProvisioningFile, [Parameter(Mandatory)][string]$RepositoryRoot)

    $run = Get-CiLaneRun -LaneId $LaneId -Version $ExpectedPowerShellVersion -RepositoryRoot $RepositoryRoot -ProvisioningFile $ProvisioningFile
    Initialize-CiLaneArtifact -Run $run
    Invoke-CiLaneExecution -Run $run
    return Write-CiLaneManifest -Run $run
}

if ($MyInvocation.InvocationName -ne '.') {
    $scratch = Join-Path ([System.IO.Path]::GetTempPath()) "pmu-lane-$( [guid]::NewGuid().ToString('N') )"
    New-Item -ItemType Directory -Path $scratch | Out-Null
    $saved = @{}
    foreach ($key in 'TMPDIR', 'TEMP', 'TMP', 'PATH', 'PSModulePath', 'PMU_QUALIFICATION_LIVE', 'PMU_CI_TEST_RUNTIME_PATH', 'PMU_CI_RUNTIME_CONTEXT') {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key)
    }
    $env:TMPDIR = $env:TEMP = $env:TMP = $scratch
    Remove-Item Env:PMU_QUALIFICATION_LIVE -ErrorAction SilentlyContinue
    try {
        if (-not $ModuleRoot) {
            $ModuleRoot = Join-Path $scratch "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))"
            & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Install-CiPowerShellModules.ps1') -ModuleRoot $ModuleRoot
            if ($LASTEXITCODE -ne 0) { throw 'Disposable dependency provisioning failed.' }
        }
        $owner = Get-CiDependencyOwner -Path $ModuleRoot
        $env:PSModulePath = Get-CiIsolatedModulePath -ModuleRoot $owner.Path
        $env:PATH = (Split-Path -Parent (Get-Process -Id $PID).Path) + [IO.Path]::PathSeparator + $saved.PATH
        $resolved = (Get-Command pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
        if ($resolved -ne (Get-Process -Id $PID).Path) { throw 'pwsh command resolution does not match the selected executable.' }
        & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'CiDependencyProbe.ps1') -ModuleRoot $owner.Path
        if ($LASTEXITCODE -ne 0) { throw 'Dependency validation failed.' }
        $status = Invoke-CiLane -LaneId $LaneId -ExpectedPowerShellVersion $ExpectedPowerShellVersion -ProvisioningFile $ProvisioningFile -RepositoryRoot $RepositoryRoot
    } finally {
        foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
        if ($owner) { Remove-CiDependencyRoot -Owner $owner }
        Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction Stop
    }
    if ($status -ne 'passed') {
        exit 1
    }
}
