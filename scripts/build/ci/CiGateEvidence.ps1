. (Join-Path $PSScriptRoot 'CiRuntimeEvidence.ps1')
. (Join-Path $PSScriptRoot 'CiTestResultSummary.ps1')
. (Join-Path $PSScriptRoot 'CiTestDetail.ps1')
. (Join-Path $PSScriptRoot 'CiLaneManifest.ps1')
. (Join-Path $PSScriptRoot 'CiGateSchema.ps1')

function Assert-CiGateConfiguration {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Expected
    )

    foreach ($field in 'id', 'name', 'runner', 'os', 'architecture', 'runtimeIdentifier', 'powershell') {
        if ($Manifest.configuration.$field -cne $Expected.$field) {
            throw "Lane configuration differs at '$field'."
        }
    }
    Assert-CiGateSelectedRuntime -Manifest $Manifest -Expected $Expected
    Assert-CiRuntimeRecord -Record @{
        Environment = $Manifest.environment
        Executable = $Manifest.selectedRuntime.Executable
    } -Expected $Manifest.selectedRuntime
    Assert-CiGateRunnerIdentity -Environment $Manifest.environment
}

function Assert-CiGateRunnerIdentity {
    param([Parameter(Mandatory)]$Environment)

    foreach ($field in 'RunnerOs', 'RunnerArch', 'ImageOs', 'ImageVersion') {
        if (-not $Environment.$field) {
            throw "Missing runner metadata '$field'."
        }
    }
    if ($Environment.RunnerEnvironment -ne 'github-hosted') {
        throw 'A GitHub-hosted runner is required.'
    }
}

function Assert-CiGateSelectedRuntime {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Expected
    )

    $runtime = $Manifest.selectedRuntime
    Assert-CiGateFieldMatch -Actual $runtime -Expected @{
        OperatingSystem = $Expected.os
        Architecture = $Expected.architecture
    }
    if ($runtime.PowerShellChannel -cne $Expected.powershell) {
        throw 'Selected runtime channel differs from lane configuration.'
    }
    if ($runtime.PowerShellVersion -notmatch '^\d+\.\d+\.\d+$') {
        throw 'Invalid selected runtime version.'
    }
    Assert-CiGateRuntimeVersion -Runtime $runtime
    $absolute = $runtime.Executable -match '^/'
    if ($Expected.os -eq 'Windows') {
        $absolute = $runtime.Executable -match '^[A-Za-z]:[\\/]'
    }
    if (-not $absolute) {
        throw 'Selected executable path is not absolute.'
    }
}

function Assert-CiGateFieldMatch {
    param(
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)][hashtable]$Expected
    )

    foreach ($name in $Expected.Keys) {
        if ($Actual.$name -ne $Expected[$name]) {
            throw "Qualification evidence differs at '$name'."
        }
    }
}

function Assert-CiGateRuntimeVersion {
    param([Parameter(Mandatory)]$Runtime)

    if ([version]$Runtime.PowerShellVersion -lt [version]'7.4.0') {
        throw 'Runtime is below the supported 7.4 minimum.'
    }
    if ($Runtime.PowerShellChannel -eq 'stable') {
        return
    }
    $pins = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'PowerShellVersions.json') -Raw | ConvertFrom-Json -AsHashtable).channels
    if ($Runtime.PowerShellVersion -cne $pins[$Runtime.PowerShellChannel].version) {
        throw 'Selected runtime differs from the explicit repository pin.'
    }
}

function Assert-CiGateProvisioning {
    param([Parameter(Mandatory)]$Manifest)

    $provision = $Manifest.provisioning
    if ($provision.sha256 -notmatch '^[a-fA-F0-9]{64}$') {
        throw 'Missing verified provisioning checksum.'
    }
    if (-not $provision.fileName -or -not $provision.hashSource) {
        throw 'Incomplete provisioning provenance.'
    }
    $expected = @{
        channel = $Manifest.configuration.powershell
        runtimeIdentifier = $Manifest.configuration.runtimeIdentifier
        version = $Manifest.selectedRuntime.PowerShellVersion
        executable = $Manifest.selectedRuntime.Executable
    }
    Assert-CiGateFieldMatch -Actual $provision -Expected $expected
    Assert-CiRuntimeRecord -Record $provision.runtime -Expected $Manifest.selectedRuntime
}

function Assert-CiGateTestEvidence {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Directory
    )

    foreach ($name in 'unit', 'integration') {
        $summary = Get-CiTestResultSummary -Path (Join-Path $Directory "$name-nunit.xml")
        $detail = @(Read-CiTestDetail -Path (Join-Path $Directory "logs/$name.log"))
        Assert-CiTestDetail -Summary $summary -Detail $detail -OperatingSystem $Manifest.configuration.os
        $serialized = @(Get-Content -LiteralPath (Join-Path $Directory "$name-details.json") -Raw -ErrorAction Stop | ConvertFrom-Json)
        Assert-CiSerializedDetail -Actual $detail -Serialized $serialized
        Assert-CiGateReportSummary -Actual $summary -Expected $Manifest.tests.$name
    }
}

function Assert-CiGateReportSummary {
    param(
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)]$Expected
    )

    foreach ($field in 'Total', 'Passed', 'Failed', 'Skipped') {
        if ($Actual.$field -ne $Expected.$field) {
            throw "Manifest '$field' differs from actual test evidence."
        }
    }
    if ($Actual.Passed -le 0 -or $Actual.Failed -ne 0) {
        throw 'Tests did not execute successfully.'
    }
}

function Assert-CiSerializedDetail {
    param(
        [Parameter(Mandatory)][object[]]$Actual,
        [Parameter(Mandatory)][object[]]$Serialized
    )

    if ($Actual.Count -ne $Serialized.Count) {
        throw 'Serialized test detail count differs from retained log.'
    }
    for ($index = 0; $index -lt $Actual.Count; $index++) {
        foreach ($name in 'File', 'Name', 'Result') {
            if ($Actual[$index].$name -cne $Serialized[$index].$name) {
                throw 'Serialized test detail differs from retained log.'
            }
        }
    }
}

function Assert-CiGateManifestIdentity {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$RunContext
    )

    foreach ($name in 'runId', 'runAttempt') {
        if ($Manifest.identity.$name -cne $RunContext.$name) {
            throw "Manifest belongs to another '$name'."
        }
    }
    if ($Manifest.identity.commitSha -cne $Manifest.commitSha -or $Manifest.identity.laneId -cne $Manifest.laneId) {
        throw 'Manifest and execution identity differ.'
    }
    if ($Manifest.identity.executionId -notmatch '^[a-f0-9]{32}$') {
        throw 'Missing unique lane execution identity.'
    }
}

function Assert-CiGateManifestEvidence {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)]$RunContext,
        [Parameter(Mandatory)][string]$Directory
    )

    Assert-CiGateManifestSchema -Manifest $Manifest
    if ($Manifest.schemaVersion -ne 1) {
        throw 'Unsupported or missing manifest schema.'
    }
    Assert-CiGateManifestIdentity -Manifest $Manifest -RunContext $RunContext
    Assert-CiGateConfiguration -Manifest $Manifest -Expected $Expected
    Assert-CiGateProvisioning -Manifest $Manifest
    Assert-CiLaneRuntimeEvidence -Directory (Join-Path $Directory 'logs') -Phase $Manifest.phases -Expected $Manifest.selectedRuntime -Identity $Manifest.identity
    Assert-CiGateTestEvidence -Manifest $Manifest -Directory $Directory
    if ((Get-CiLaneStatus -Mismatch $Manifest.mismatches -Phase $Manifest.phases -Summary $Manifest.tests) -ne 'passed') {
        throw 'Manifest evidence does not establish a passed lane.'
    }
}
