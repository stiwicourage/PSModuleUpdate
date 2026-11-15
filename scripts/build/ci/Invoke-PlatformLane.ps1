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
        Where-Object { $_.id -eq $LaneId }
    if (-not $lane) {
        throw "Unknown lane '$LaneId'."
    }

    return $lane
}

function Invoke-CiLanePhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Phase,
        $Context
    )

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $launch = Initialize-CiPhaseLaunch -Phase $Phase -Context $Context
    $exitCode = Invoke-CiPhaseChild -Launch $launch -LogPath $Phase.LogPath
    return Get-CiPhaseResult -Phase $Phase -Launch $launch -Watch $watch -ExitCode $exitCode
}

function Initialize-CiPhaseLaunch {
    # Phase contains Name, Command, LogPath and WorkingDirectory for one child process.
    param([hashtable]$Phase, $Context)
    $launch = Get-CiPhaseContext -Name $Phase.Name -LogPath $Phase.LogPath -Context $Context
    $launch.WorkingDirectory = $Phase.WorkingDirectory
    $launch.Command = $Phase.Command
    $contextFile = "$($Phase.LogPath).context.json"
    $launch | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $contextFile
    return $launch
}

function Invoke-CiPhaseChild {
    param($Launch, [string]$LogPath)
    $contextFile = "$LogPath.context.json"
    & $Launch.Expected.Executable -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Invoke-CiPhaseProcess.ps1') -ContextFile $contextFile 2>&1 |
        Tee-Object -FilePath $LogPath | Out-Host
    return $LASTEXITCODE
}

function Get-CiPhaseProcessEvidence {
    param($Launch)
    $runtime = if (Test-Path -LiteralPath $Launch.RuntimePath) {
        Get-Content -LiteralPath $Launch.RuntimePath -Raw | ConvertFrom-Json
    }
    return [ordered]@{
        Environment = $runtime.Environment
        Executable = $runtime.Executable
        ProcessId = $runtime.ProcessId
    }
}

function Get-CiPhaseResult {
    param([hashtable]$Phase, $Launch, $Watch, [int]$ExitCode)
    $evidence = Get-CiPhaseProcessEvidence -Launch $Launch
    $result = [ordered]@{
        Name = $Phase.Name
        ExitCode = $ExitCode
        DurationSeconds = [math]::Round($Watch.Elapsed.TotalSeconds, 1)
        LogFile = Split-Path -Leaf $Phase.LogPath
        RuntimeFile = Split-Path -Leaf $Launch.RuntimePath
        TestRuntimeFile = Split-Path -Leaf $Launch.TestRuntimePath
    }
    return ConvertTo-CiPhaseResultObject -Result $result -Evidence $evidence
}

function ConvertTo-CiPhaseResultObject {
    param([System.Collections.Specialized.OrderedDictionary]$Result, $Evidence)
    foreach ($entry in $Evidence.GetEnumerator()) {
        $Result[$entry.Key] = $entry.Value
    }
    return [pscustomobject]$Result
}

function Get-CiPhaseContext {
    param(
        [string]$Name,
        [string]$LogPath,
        $Context
    )

    if (-not $Context) {
        $Context = Get-CiDefaultPhaseContext
    }
    $identity = @{} + $Context.Identity
    $identity.phase = $Name
    return Get-CiPhaseLaunchRecord -Expected $Context.Expected -Identity $identity -LogPath $LogPath
}

function Get-CiDefaultPhaseContext {
    param()
    $actual = Get-CiRuntimeRecord
    return @{
        Expected = @{
            OperatingSystem = $actual.Environment.OperatingSystem
            Architecture = $actual.Environment.ProcessArchitecture
            PowerShellVersion = $actual.Environment.PowerShellVersion
            PowerShellChannel = 'stable'
            Executable = $actual.Executable
        }
        Identity = @{}
    }
}

function Get-CiPhaseLaunchRecord {
    param($Expected, $Identity, [string]$LogPath)
    return @{
        Expected = $Expected
        Identity = $Identity
        RuntimePath = "$LogPath.runtime.json"
        TestRuntimePath = "$LogPath.test-runtime.json"
    }
}

function Get-CiModuleVersion {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param()

    $module = @{}
    foreach ($name in 'Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet', 'Microsoft.PowerShell.PlatyPS') {
        $module[$name] = @(Get-Module -ListAvailable -Name $name | Sort-Object Version -Descending |
                Select-Object -First 1 | ForEach-Object { $_.Version.ToString() })
    }

    return $module
}

function Get-CiLanePhaseDefinition {
    [OutputType([object[]])]
    [CmdletBinding()]
    param()

    return @(
        Get-CiPhaseDefinition -Name 'build' -Command 'Import-Module Pester -RequiredVersion 5.7.1; Import-Module NovaModuleTools -ErrorAction Stop; Invoke-NovaBuild'
        Get-CiPhaseDefinition -Name 'unit' -Command 'Import-Module Pester -RequiredVersion 5.7.1; Import-Module NovaModuleTools -ErrorAction Stop; Invoke-NovaTest -OutputVerbosity Detailed -OutputRenderMode Ansi'
        Get-CiPhaseDefinition -Name 'integration' -Command 'Import-Module Pester -RequiredVersion 5.7.1; Import-Module NovaModuleTools -ErrorAction Stop; Test-NovaBuild -OutputVerbosity Detailed -OutputRenderMode Ansi'
    )
}

function Get-CiPhaseDefinition {
    param([string]$Name, [string]$Command)
    return @{
        Name = $Name
        Command = $Command
    }
}

function Invoke-CiLanePhaseSet {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$LogDirectory,
        [Parameter(Mandatory)]$Context
    )

    return Invoke-CiLanePhaseSequence -RepositoryRoot $RepositoryRoot -LogDirectory $LogDirectory -Context $Context
}

function Invoke-CiLanePhaseSequence {
    param([string]$RepositoryRoot, [string]$LogDirectory, $Context)
    $result = @()
    foreach ($definition in Get-CiLanePhaseDefinition) {
        $phase = Get-CiPhaseInvocation -Definition $definition -RepositoryRoot $RepositoryRoot -LogDirectory $LogDirectory
        $result += Invoke-CiLanePhase -Phase $phase -Context $Context
        if ($result[-1].ExitCode -ne 0) {
            break
        }
    }

    return $result
}

function Get-CiPhaseInvocation {
    param($Definition, [string]$RepositoryRoot, [string]$LogDirectory)
    return @{
        Name = $Definition.Name
        Command = $Definition.Command
        LogPath = Join-Path $LogDirectory "$( $Definition.Name ).log"
        WorkingDirectory = $RepositoryRoot
    }
}

function Copy-CiTestResult {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    $summary = @{}
    $source = Get-CiTestResultSource
    $paths = Get-CiTestResultLocation -RepositoryRoot $RepositoryRoot -OutputDirectory $OutputDirectory
    foreach ($key in $source.Keys) {
        Copy-CiTestResultEntry -Key $key -Source $source[$key] -Summary $summary -Paths $paths
    }
    return $summary
}

function Get-CiTestResultSource {
    param()
    return [ordered]@{
        unit = @('artifacts/UnitTestResults.xml', 'unit-nunit.xml')
        integration = @('artifacts/TestResults.xml', 'integration-nunit.xml')
    }
}

function Get-CiTestResultLocation {
    param([string]$RepositoryRoot, [string]$OutputDirectory)
    return @{
        RepositoryRoot = $RepositoryRoot
        OutputDirectory = $OutputDirectory
    }
}

function Copy-CiTestResultEntry {
    param([string]$Key, [string[]]$Source, [hashtable]$Summary, [hashtable]$Paths)
    $path = Join-Path $Paths.RepositoryRoot $Source[0]
    if (Test-Path -LiteralPath $path) {
        Copy-Item -LiteralPath $path -Destination (Join-Path $Paths.OutputDirectory $Source[1])
        $Summary[$Key] = Get-CiTestResultSummary -Path $path
        Save-CiTestResultDetail -Summary $Summary[$Key] -Key $Key -OutputDirectory $Paths.OutputDirectory
    }
}

function Save-CiTestResultDetail {
    param($Summary, [string]$Key, [string]$OutputDirectory)
    $log = Join-Path $OutputDirectory "logs/$Key.log"
    $detail = @(Read-CiTestDetail -Path $log)
    Assert-CiTestDetail -Summary $Summary -Detail $detail -OperatingSystem (Get-CiLaneOperatingSystem)
    $detail | ConvertTo-Json -Depth 4 -AsArray | Set-Content -LiteralPath (Join-Path $OutputDirectory "$Key-details.json")
    $Summary.SkippedName = @($detail | Where-Object Result -eq 'Skipped' | ForEach-Object { "$($_.File): $($_.Name)" })
}

function Write-CiLaneSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest
    )

    $line = @(Get-CiLaneSummaryLine -Manifest $Manifest)
    if ($env:GITHUB_STEP_SUMMARY) {
        Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value $line
    }
    $line | Out-Host
}

function Get-CiLaneSummaryLine {
    param($Manifest)
    $line = @("### $( $Manifest.laneId ): $( $Manifest.status )", '')
    $line += $Manifest.mismatches | ForEach-Object { "- Environment mismatch: $_" }
    $line += $Manifest.phases | ForEach-Object { "- $( $_.Name ): exit code $( $_.ExitCode ), $( $_.DurationSeconds )s" }
    foreach ($key in $Manifest.tests.Keys) {
        $line += Get-CiLaneTestSummaryLine -Key $key -Test $Manifest.tests[$key]
    }
    return $line
}

function Get-CiLaneTestSummaryLine {
    param([string]$Key, $Test)
    "- $Key tests: $( $Test.Passed ) passed, $( $Test.Failed ) failed, $( $Test.Skipped ) skipped"
    $Test.SkippedName | ForEach-Object { "  - skipped (see test source and logs for the reason): $_" }
    if ($Test.Skipped -gt 0 -and @($Test.SkippedName).Count -eq 0) {
        "  - skipped tests are not named in the report; see logs/*.log ([!] lines) and the test source for the reason"
    }
}

function Get-CiLaneIdentity {
    param([string]$LaneId)

    $identity = @{
        laneId = $LaneId
        executionId = [guid]::NewGuid().ToString('N')
    }
    $defaults = Get-CiLaneIdentityDefault
    foreach ($name in $defaults.Keys) {
        $identity[$name] = Get-CiLaneIdentityValue -Name $defaults[$name][0] -Default $defaults[$name][1]
    }
    return $identity
}

function Get-CiLaneIdentityDefault {
    param()
    return @{
        commitSha = @('GITHUB_SHA', 'local')
        runId = @('GITHUB_RUN_ID', 'local')
        runAttempt = @('GITHUB_RUN_ATTEMPT', '1')
    }
}

function Get-CiLaneIdentityValue {
    param([string]$Name, [string]$Default)
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ($value) {
        return $value
    }
    return $Default
}

function Get-CiLaneRun {
    param(
        [string]$LaneId,
        [string]$Version,
        [string]$RepositoryRoot,
        [string]$ProvisioningFile
    )

    $lane = Get-CiLaneDefinition -LaneId $LaneId
    $actual = Get-CiLaneEnvironment
    $expected = Get-CiLaneExpectation -Lane $lane -Actual $actual -Version $Version
    $run = Get-CiLaneRunIdentity -Lane $lane -Actual $actual -Expected $expected -LaneId $LaneId
    Initialize-CiLaneRunLocation -Run $run -RepositoryRoot $RepositoryRoot -ProvisioningFile $ProvisioningFile
    return $run
}

function Get-CiLaneExpectation {
    param($Lane, $Actual, [string]$Version)
    if (-not $Version) {
        $Version = $Actual.PowerShellVersion
    }
    return @{
        OperatingSystem = $Lane.os
        Architecture = $Lane.architecture
        PowerShellChannel = $Lane.powershell
        PowerShellVersion = $Version
        Executable = (Get-Process -Id $PID).Path
    }
}

function Get-CiLaneRunIdentity {
    param($Lane, $Actual, $Expected, [string]$LaneId)
    return @{
        Lane = $Lane
        Actual = $Actual
        Expected = $Expected
        Identity = Get-CiLaneIdentity -LaneId $LaneId
    }
}

function Initialize-CiLaneRunLocation {
    param([hashtable]$Run, [string]$RepositoryRoot, [string]$ProvisioningFile)
    $output = Join-Path $RepositoryRoot "artifacts/ci/$($Run.Identity.laneId)"
    $Run.RepositoryRoot = $RepositoryRoot
    $Run.Output = $output
    $Run.Logs = Join-Path $output 'logs'
    $Run.ProvisioningFile = $ProvisioningFile
    $Run.Provisioning = $null
    $Run.Phase = @()
    $Run.Summary = @()
    $Run.Mismatch = @()
}

function Initialize-CiLaneArtifact {
    param([Parameter(Mandatory)][hashtable]$Run)

    if (Test-Path -LiteralPath $Run.Output) {
        Remove-Item -LiteralPath $Run.Output -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Run.Logs -Force | Out-Null
    foreach ($report in 'UnitTestResults.xml', 'TestResults.xml') {
        Remove-Item -LiteralPath (Join-Path $Run.RepositoryRoot "artifacts/$report") -Force -ErrorAction SilentlyContinue
    }
    $PSVersionTable | Out-String | Set-Content -LiteralPath (Join-Path $Run.Output 'PSVersionTable.txt')
}

function Assert-CiLaneProvisioning {
    param([Parameter(Mandatory)][hashtable]$Run)

    if (-not $Run.ProvisioningFile) {
        return
    }
    $Run.Provisioning = Get-Content -LiteralPath $Run.ProvisioningFile -Raw -ErrorAction Stop | ConvertFrom-Json
    Assert-CiRuntimeRecord -Record $Run.Provisioning.runtime -Expected $Run.Expected
    if ($Run.Provisioning.runtimeIdentifier -ne $Run.Lane.runtimeIdentifier) {
        throw 'Provisioned runtime identifier differs from lane.'
    }
    if ($Run.Provisioning.version -ne $Run.Expected.PowerShellVersion) {
        throw 'Provisioned version differs from selected runtime.'
    }
}

function Invoke-CiLaneExecution {
    param([Parameter(Mandatory)][hashtable]$Run)

    $Run.Summary = @{}
    $Run.Mismatch = @(Test-CiLaneEnvironment -Expected $Run.Expected -Actual $Run.Actual -RequireGitHubHosted:([bool]$env:GITHUB_ACTIONS))
    if ($Run.Mismatch.Count -gt 0) {
        return
    }
    try {
        Invoke-CiLaneValidatedPhaseSet -Run $Run
    } catch {
        $Run.Mismatch += $_.Exception.Message
    }
}

function Invoke-CiLaneValidatedPhaseSet {
    param([hashtable]$Run)
    Assert-CiLaneProvisioning -Run $Run
    $Run.Phase = Invoke-CiLanePhaseSet -RepositoryRoot $Run.RepositoryRoot -LogDirectory $Run.Logs -Context @{
        Expected = $Run.Expected
        Identity = $Run.Identity
    }
    $Run.Summary = Copy-CiTestResult -RepositoryRoot $Run.RepositoryRoot -OutputDirectory $Run.Output
    Assert-CiLaneRuntimeEvidence -Directory $Run.Logs -Phase $Run.Phase -Expected $Run.Expected -Identity $Run.Identity
}

function Write-CiLaneManifest {
    param([Parameter(Mandatory)][hashtable]$Run)

    $manifest = Build-CiLaneManifest -Run $Run -Module (Get-CiModuleVersion)
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
    param(
        [Parameter(Mandatory)][string]$LaneId,
        [string]$ExpectedPowerShellVersion,
        [string]$ProvisioningFile,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $run = Get-CiLaneRun -LaneId $LaneId -Version $ExpectedPowerShellVersion -RepositoryRoot $RepositoryRoot -ProvisioningFile $ProvisioningFile
    Initialize-CiLaneArtifact -Run $run
    Invoke-CiLaneExecution -Run $run
    return Write-CiLaneManifest -Run $run
}

function Initialize-CiLaneScratch {
    param()
    $scratch = Join-Path ([System.IO.Path]::GetTempPath()) "pmu-lane-$( [guid]::NewGuid().ToString('N') )"
    New-Item -ItemType Directory -Path $scratch | Out-Null
    $saved = Get-CiLaneSavedEnvironment
    $env:TMPDIR = $env:TEMP = $env:TMP = $scratch
    Remove-Item Env:PMU_QUALIFICATION_LIVE -ErrorAction SilentlyContinue
    return @{
        Path = $scratch
        Saved = $saved
    }
}

function Get-CiLaneSavedEnvironment {
    param()
    $saved = @{}
    foreach ($key in 'TMPDIR', 'TEMP', 'TMP', 'PATH', 'PSModulePath', 'PMU_QUALIFICATION_LIVE', 'PMU_CI_TEST_RUNTIME_PATH', 'PMU_CI_RUNTIME_CONTEXT') {
        $saved[$key] = [Environment]::GetEnvironmentVariable($key)
    }
    return $saved
}

function Invoke-CiPlatformLane {
    param([hashtable]$Options)
    $scratch = Initialize-CiLaneScratch
    try {
        Initialize-CiLaneModuleOwner -Options $Options -Scratch $scratch
        $owner = $Options.Owner
        Initialize-CiLaneProcessEnvironment -Owner $owner -Saved $scratch.Saved
        Assert-CiLaneDependencyProbe -ModuleRoot $owner.Path
        $Options.Status = Invoke-CiLane -LaneId $Options.LaneId -ExpectedPowerShellVersion $Options.ExpectedPowerShellVersion -ProvisioningFile $Options.ProvisioningFile -RepositoryRoot $Options.RepositoryRoot
    } finally {
        Restore-CiLaneScratch -Scratch $scratch -Owner $owner
    }
}

function Initialize-CiLaneModuleOwner {
    param([hashtable]$Options, $Scratch)
    if (-not $Options.ModuleRoot) {
        $Options.ModuleRoot = Join-Path $Scratch.Path "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))"
        Invoke-CiLaneDependencyProvision -ModuleRoot $Options.ModuleRoot
    }
    $Options.Owner = Get-CiDependencyOwner -Path $Options.ModuleRoot
}

function Invoke-CiLaneDependencyProvision {
    param([string]$ModuleRoot)
    & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Install-CiPowerShellModules.ps1') -ModuleRoot $ModuleRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Disposable dependency provisioning failed.'
    }
}

function Initialize-CiLaneProcessEnvironment {
    param([hashtable]$Owner, [hashtable]$Saved)
    $env:PSModulePath = Get-CiIsolatedModulePath -ModuleRoot $Owner.Path
    $env:PATH = (Split-Path -Parent (Get-Process -Id $PID).Path) + [IO.Path]::PathSeparator + $Saved.PATH
    $resolved = (Get-Command pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    if ($resolved -ne (Get-Process -Id $PID).Path) {
        throw 'pwsh command resolution does not match the selected executable.'
    }
}

function Assert-CiLaneDependencyProbe {
    param([string]$ModuleRoot)
    & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'CiDependencyProbe.ps1') -ModuleRoot $ModuleRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Dependency validation failed.'
    }
}

function Restore-CiLaneScratch {
    param($Scratch, $Owner)
    foreach ($key in $Scratch.Saved.Keys) {
        [Environment]::SetEnvironmentVariable($key, $Scratch.Saved[$key])
    }
    if ($Owner) {
        Remove-CiDependencyRoot -Owner $Owner
    }
    Remove-Item -LiteralPath $Scratch.Path -Recurse -Force -ErrorAction Stop
}

if ($MyInvocation.InvocationName -ne '.') {
    $options = @{
        LaneId = $LaneId
        ExpectedPowerShellVersion = $ExpectedPowerShellVersion
        ProvisioningFile = $ProvisioningFile
        ModuleRoot = $ModuleRoot
        RepositoryRoot = $RepositoryRoot
    }
    Invoke-CiPlatformLane -Options $options
    if ($options.Status -ne 'passed') {
        exit 1
    }
}
