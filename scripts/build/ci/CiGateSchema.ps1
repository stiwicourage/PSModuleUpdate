function Assert-CiRequiredField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string[]]$Name
    )

    if ($Object -isnot [System.Collections.IDictionary]) {
        throw 'Expected a JSON object.'
    }
    foreach ($field in $Name) {
        if (-not $Object.Contains($field)) {
            throw "Required manifest field '$field' is missing."
        }
    }
}

function Assert-CiNonnegativeInteger {
    param([AllowNull()]$Value)

    if ($Value -isnot [int] -and $Value -isnot [long]) {
        throw 'Expected an integer evidence value.'
    }
    if ($Value -lt 0) {
        throw 'Expected a nonnegative evidence value.'
    }
}

function Assert-CiGateSummarySchema {
    param([Parameter(Mandatory)]$Summary)

    Assert-CiRequiredField -Object $Summary -Name @('Total', 'Passed', 'Failed', 'Skipped', 'SkippedName')
    foreach ($name in 'Total', 'Passed', 'Failed', 'Skipped') {
        Assert-CiNonnegativeInteger -Value $Summary[$name]
    }
    if (@($Summary.SkippedName).Count -ne $Summary.Skipped) {
        throw 'Manifest is missing skipped-test identities.'
    }
}

function Assert-CiGatePhaseSchema {
    param([Parameter(Mandatory)]$Phase)

    Assert-CiRequiredField -Object $Phase -Name @('Name', 'ExitCode', 'ProcessId', 'Environment', 'Executable', 'DurationSeconds', 'LogFile', 'RuntimeFile', 'TestRuntimeFile')
    Assert-CiNonnegativeInteger -Value $Phase.ExitCode
    Assert-CiNonnegativeInteger -Value $Phase.ProcessId
    $number = $Phase.DurationSeconds
    if ($number.GetType().Name -notin 'Int32', 'Int64', 'Double', 'Decimal') {
        throw 'Invalid phase duration.'
    }
    if (-not [double]::IsFinite($number) -or $number -lt 0) {
        throw 'Invalid phase duration.'
    }
    if ($Phase.LogFile -cne "$($Phase.Name).log") {
        throw 'Unexpected phase log file.'
    }
    if ($Phase.RuntimeFile -cne "$($Phase.Name).log.runtime.json") {
        throw 'Unexpected phase runtime file.'
    }
    if ($Phase.TestRuntimeFile -cne "$($Phase.Name).log.test-runtime.json") {
        throw 'Unexpected test runtime file.'
    }
}

function Assert-CiGateModuleSchema {
    param([Parameter(Mandatory)]$Module)

    $required = @('Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet', 'Microsoft.PowerShell.PlatyPS')
    Assert-CiRequiredField -Object $Module -Name $required
    foreach ($name in $required) {
        if (@($Module[$name]).Count -ne 1) {
            throw "Missing selected module availability '$name'."
        }
        if ($Module[$name][0] -notmatch '^\d+\.\d+\.\d+(?:\.\d+)?$') {
            throw "Invalid module version '$name'."
        }
    }
    if ($Module['Microsoft.PowerShell.PSResourceGet'][0] -cne '1.2.0') {
        throw 'PSResourceGet 1.2.0 availability is required.'
    }
}

function Assert-CiGateManifestSchema {
    param([Parameter(Mandatory)]$Manifest)

    Assert-CiRequiredField -Object $Manifest -Name @('schemaVersion', 'laneId', 'commitSha', 'status', 'identity', 'configuration', 'selectedRuntime', 'environment', 'phases', 'tests', 'modules', 'mismatches', 'provisioning')
    Assert-CiNonnegativeInteger -Value $Manifest.schemaVersion
    Assert-CiRequiredField -Object $Manifest.identity -Name @('laneId', 'commitSha', 'runId', 'runAttempt', 'executionId')
    Assert-CiGateModuleSchema -Module $Manifest.modules
    foreach ($phase in $Manifest.phases) {
        Assert-CiGatePhaseSchema -Phase $phase
    }
    foreach ($name in 'unit', 'integration') {
        Assert-CiGateSummarySchema -Summary $Manifest.tests[$name]
    }
}
