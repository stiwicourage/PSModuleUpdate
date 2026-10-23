[CmdletBinding()]
param(
    [string]$LaneId,
    [string]$ExpectedPowerShellVersion,
    [string]$ProvisioningFile,
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
)

. (Join-Path $PSScriptRoot 'CiLaneEnvironment.ps1')
. (Join-Path $PSScriptRoot 'CiTestResultSummary.ps1')
. (Join-Path $PSScriptRoot 'CiLaneManifest.ps1')

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
        [Parameter(Mandatory)][string]$WorkingDirectory
    )

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $script = "`$ErrorActionPreference='Stop'; $Command"
        & (Get-Process -Id $PID).Path -NoLogo -NoProfile -Command $script 2>&1 | Tee-Object -FilePath $LogPath | Out-Host
        $exitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    return [pscustomobject][ordered]@{
        Name = $Name
        ExitCode = $exitCode
        DurationSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 1)
        LogFile = Split-Path -Leaf $LogPath
    }
}

function Get-CiModuleVersion {
    [CmdletBinding()]
    param()

    $module = @{}
    foreach ($name in 'Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet') {
        $module[$name] = @(Get-Module -ListAvailable -Name $name | Sort-Object Version -Descending |
                Select-Object -First 1 | ForEach-Object {$_.Version.ToString()})
    }

    return $module
}

function Get-CiLanePhaseDefinition {
    [CmdletBinding()]
    param()

    return @(
        @{Name = 'build'; Command = 'Import-Module NovaModuleTools -ErrorAction Stop; Invoke-NovaBuild'}
        @{Name = 'unit'; Command = 'Import-Module NovaModuleTools -ErrorAction Stop; Invoke-NovaTest'}
        @{Name = 'integration'; Command = 'Import-Module NovaModuleTools -ErrorAction Stop; Test-NovaBuild'}
    )
}

function Invoke-CiLanePhaseSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$LogDirectory
    )

    $result = @()
    foreach ($definition in Get-CiLanePhaseDefinition) {
        $log = Join-Path $LogDirectory "$( $definition.Name ).log"
        $result += Invoke-CiLanePhase -Name $definition.Name -Command $definition.Command -LogPath $log -WorkingDirectory $RepositoryRoot
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

function Invoke-CiLane {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LaneId,
        [string]$ExpectedPowerShellVersion,
        [string]$ProvisioningFile,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $lane = Get-CiLaneDefinition -LaneId $LaneId
    $output = Join-Path $RepositoryRoot "artifacts/ci/$LaneId"
    $logDirectory = Join-Path $output 'logs'
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $PSVersionTable | Out-String | Set-Content -LiteralPath (Join-Path $output 'PSVersionTable.txt')

    $actual = Get-CiLaneEnvironment
    $version = if ($ExpectedPowerShellVersion) {$ExpectedPowerShellVersion} else {$actual.PowerShellVersion}
    $expected = [pscustomobject]@{
        OperatingSystem = $lane.os
        Architecture = $lane.architecture
        PowerShellChannel = $lane.powershell
        PowerShellVersion = $version
    }
    $mismatch = @(Test-CiLaneEnvironment -Expected $expected -Actual $actual -RequireGitHubHosted:([bool]$env:GITHUB_ACTIONS))
    $mismatch | ForEach-Object {Write-Output "::error title=$LaneId::$_"}

    $phase = @()
    $summary = @{}
    if ($mismatch.Count -eq 0) {
        $phase = Invoke-CiLanePhaseSet -RepositoryRoot $RepositoryRoot -LogDirectory $logDirectory
        $summary = Copy-CiTestResult -RepositoryRoot $RepositoryRoot -OutputDirectory $output
    }

    $commit = if ($env:GITHUB_SHA) {$env:GITHUB_SHA} else {'local'}
    $manifest = Build-CiLaneManifest -LaneId $LaneId -CommitSha $commit -Environment $actual -Mismatch $mismatch -Phase $phase -Summary $summary -Module (Get-CiModuleVersion)
    if ($ProvisioningFile -and (Test-Path -LiteralPath $ProvisioningFile)) {
        $manifest['provisioning'] = Get-Content -LiteralPath $ProvisioningFile -Raw | ConvertFrom-Json
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'lane-manifest.json')
    Write-CiLaneSummary -Manifest $manifest

    return $manifest.status
}

if ($MyInvocation.InvocationName -ne '.') {
    $scratch = Join-Path ([System.IO.Path]::GetTempPath()) "pmu-lane-$( [guid]::NewGuid().ToString('N') )"
    New-Item -ItemType Directory -Path $scratch | Out-Null
    $saved = @{TMPDIR = $env:TMPDIR; TEMP = $env:TEMP; TMP = $env:TMP}
    $env:TMPDIR = $env:TEMP = $env:TMP = $scratch
    Remove-Item Env:PMU_QUALIFICATION_LIVE -ErrorAction SilentlyContinue
    try {
        $status = Invoke-CiLane -LaneId $LaneId -ExpectedPowerShellVersion $ExpectedPowerShellVersion -ProvisioningFile $ProvisioningFile -RepositoryRoot $RepositoryRoot
    } finally {
        $env:TMPDIR = $saved.TMPDIR
        $env:TEMP = $saved.TEMP
        $env:TMP = $saved.TMP
        Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($status -ne 'passed') {
        exit 1
    }
}
