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
    Assert-CiGatePhaseDuration -Value $Phase.DurationSeconds
    Assert-CiGatePhaseFile -Phase $Phase -Field LogFile -Suffix '.log' -Description 'phase log'
    Assert-CiGatePhaseFile -Phase $Phase -Field RuntimeFile -Suffix '.log.runtime.json' -Description 'phase runtime'
    Assert-CiGatePhaseFile -Phase $Phase -Field TestRuntimeFile -Suffix '.log.test-runtime.json' -Description 'test runtime'
}

function Assert-CiGatePhaseDuration {
    param($Value)

    if ($Value.GetType().Name -notin 'Int32', 'Int64', 'Double', 'Decimal') {
        throw 'Invalid phase duration.'
    }
    if (-not [double]::IsFinite($Value) -or $Value -lt 0) {
        throw 'Invalid phase duration.'
    }
}

function Assert-CiGatePhaseFile {
    param(
        $Phase,
        [string]$Field,
        [string]$Suffix,
        [string]$Description
    )

    if ($Phase.$Field -cne "$($Phase.Name)$Suffix") {
        throw "Unexpected $Description file."
    }
}

function Assert-CiGateModuleSchema {
    param([Parameter(Mandatory)]$Module)

    $required = @('Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet', 'Microsoft.PowerShell.PlatyPS')
    Assert-CiRequiredField -Object $Module -Name $required
    foreach ($name in $required) {
        Assert-CiGateModuleAvailability -Module $Module -Name $name
    }
    if ($Module['Microsoft.PowerShell.PSResourceGet'][0] -cne '1.2.0') {
        throw 'PSResourceGet 1.2.0 availability is required.'
    }
}

function Assert-CiGateModuleAvailability {
    param($Module, [string]$Name)

    if (@($Module[$Name]).Count -ne 1) {
        throw "Missing selected module availability '$Name'."
    }
    if ($Module[$Name][0] -notmatch '^\d+\.\d+\.\d+(?:\.\d+)?$') {
        throw "Invalid module version '$Name'."
    }
}

function Assert-CiGateManifestSchema {
    param([Parameter(Mandatory)]$Manifest)

    Assert-CiRequiredField -Object $Manifest -Name @('schemaVersion', 'laneId', 'commitSha', 'status', 'identity', 'configuration', 'selectedRuntime', 'environment', 'phases', 'tests', 'modules', 'mismatches', 'provisioning')
    Assert-CiNonnegativeInteger -Value $Manifest.schemaVersion
    Assert-CiRequiredField -Object $Manifest.identity -Name @('laneId', 'commitSha', 'runId', 'runAttempt', 'executionId')
    Assert-CiGateModuleSchema -Module $Manifest.modules
    Assert-CiGateNativeSchema -Provisioning $Manifest.provisioning
    foreach ($phase in $Manifest.phases) {
        Assert-CiGatePhaseSchema -Phase $phase
    }

    foreach ($name in 'unit', 'integration') {
        Assert-CiGateSummarySchema -Summary $Manifest.tests[$name]
    }
}

function Assert-CiGateNativeSchema {
    param($Provisioning)
    Assert-CiRequiredField -Object $Provisioning -Name @('directory', 'nativeProvider')
    Assert-CiRequiredField -Object $Provisioning.nativeProvider -Name @('name', 'sourceRepository', 'sourceUri', 'requestedVersion', 'actualVersion', 'manifestPath', 'archiveBundledVersion')
    if ($Provisioning.nativeProvider.archiveBundledVersion -notmatch '^\d+\.\d+\.\d+$') {
        throw 'Missing archive-bundled native provider version.'
    }
}
