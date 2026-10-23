[CmdletBinding()]
param(
    [string]$ManifestDirectory = 'lane-manifests',
    [string]$LanePath = (Join-Path $PSScriptRoot 'CiLanes.json')
)

$script:RequiredJob = @('plan', 'quality', 'platform')
. (Join-Path $PSScriptRoot 'CiGateEvidence.ps1')

function ConvertTo-CiGateJobResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$NeedsJson
    )

    $needs = $NeedsJson | ConvertFrom-Json -AsHashtable
    $result = @{}
    foreach ($name in $needs.Keys) {
        $result[$name] = $needs[$name].result
    }

    return $result
}

function Get-CiGateJobFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$JobResult
    )

    foreach ($name in $script:RequiredJob) {
        if (-not $JobResult.ContainsKey($name)) {
            "Required job '$name' reported no result."
        } elseif ($JobResult[$name] -ne 'success') {
            "Required job '$name' finished with result '$( $JobResult[$name] )'."
        }
    }
}

function Read-CiLaneManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return
    }

    foreach ($file in Get-ChildItem -LiteralPath $Directory -Recurse -File -Filter 'lane-manifest.json') {
        try {
            $entry = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            if ($entry -isnot [System.Collections.IDictionary]) { throw 'Manifest must be a JSON object.' }
            $entry['_artifactDirectory'] = $file.Directory.FullName
            $entry
        } catch {
            @{ laneId = '<invalid>'; readError = $_.Exception.Message }
        }
    }
}

function Get-CiLaneManifestFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LaneId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Manifest,
        [Parameter(Mandatory)][string]$CommitSha,
        [Parameter(Mandatory)]$RunContext
    )

    $own = @($Manifest | Where-Object {$_.laneId -eq $LaneId})
    if ($own.Count -ne 1) {
        return "Lane '$LaneId' produced $( if ($own.Count -eq 0) {'no manifest'} else {"$( $own.Count ) manifests"} )."
    }
    if ($own[0].status -ne 'passed') {
        "Lane '$LaneId' manifest status is '$( $own[0].status )'."
    }
    if ($own[0].commitSha -ne $CommitSha) {
        "Lane '$LaneId' manifest belongs to commit '$( $own[0].commitSha )', not '$CommitSha'."
    }
    try {
        $entry = $own[0]
        $expected = @($RunContext.lanes | Where-Object id -eq $LaneId)
        if ($expected.Count -ne 1) { throw 'Lane has no unique expected configuration.' }
        $artifactName = "pmu-ci-lane-$($RunContext.runId)-$($RunContext.runAttempt)-$LaneId"
        if ((Split-Path -Leaf $entry._artifactDirectory) -cne $artifactName) { throw 'Manifest is not in its current-run named artifact directory.' }
        Assert-CiGateManifestEvidence -Manifest $entry -Expected $expected[0] -RunContext $RunContext -Directory $entry._artifactDirectory
    } catch {
        "Lane '$LaneId' evidence is invalid: $($_.Exception.Message)"
    }
}

function Test-CiGateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$JobResult,
        [Parameter(Mandatory)][string[]]$ExpectedLaneId,
        [Parameter(Mandatory)][string]$ManifestDirectory,
        $RunContext
    )

    if (-not $RunContext) { $RunContext = Get-CiGateRunContext -LanePath $LanePath }
    foreach ($name in 'commitSha', 'runId', 'runAttempt') {
        if ([string]::IsNullOrWhiteSpace($RunContext.$name)) { return 'Gate requires nonempty current commit, run id and attempt.' }
    }
    $manifest = @(Read-CiLaneManifest -Directory $ManifestDirectory)
    Get-CiGateJobFailure -JobResult $JobResult
    foreach ($laneId in $ExpectedLaneId) {
        Get-CiLaneManifestFailure -LaneId $laneId -Manifest $manifest -CommitSha $RunContext.commitSha -RunContext $RunContext
    }
    foreach ($entry in $manifest | Where-Object {$_.laneId -notin $ExpectedLaneId}) {
        "Unexpected lane manifest '$( $entry.laneId )'."
    }
}

function Get-CiGateRunContext {
    param([Parameter(Mandatory)][string]$LanePath)

    return @{
        commitSha = $env:GITHUB_SHA
        runId = $env:GITHUB_RUN_ID
        runAttempt = $env:GITHUB_RUN_ATTEMPT
        lanes = (Get-Content -LiteralPath $LanePath -Raw | ConvertFrom-Json).lanes
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $expectedLaneId = @((Get-Content -LiteralPath $LanePath -Raw | ConvertFrom-Json).lanes | ForEach-Object {$_.id})
    $failure = @(Test-CiGateResult -JobResult (ConvertTo-CiGateJobResult -NeedsJson $env:NEEDS_JSON) `
            -ExpectedLaneId $expectedLaneId `
            -ManifestDirectory $ManifestDirectory)

    if ($failure.Count -gt 0) {
        $failure | ForEach-Object {Write-Output "::error title=ci-gate::$_"}
        exit 1
    }

    Write-Information "ci-gate passed: all required jobs succeeded and $( $expectedLaneId.Count ) lane manifests passed for $env:GITHUB_SHA." -InformationAction Continue
}
