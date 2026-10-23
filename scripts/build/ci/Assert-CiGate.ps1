[CmdletBinding()]
param(
    [string]$ManifestDirectory = 'lane-manifests',
    [string]$LanePath = (Join-Path $PSScriptRoot 'CiLanes.json')
)

$script:RequiredJob = @('plan', 'quality', 'platform')

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

    Get-ChildItem -LiteralPath $Directory -Recurse -File -Filter 'lane-manifest.json' |
            ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json}
}

function Get-CiLaneManifestFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LaneId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Manifest,
        [Parameter(Mandatory)][string]$CommitSha
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
}

function Test-CiGateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$JobResult,
        [Parameter(Mandatory)][string[]]$ExpectedLaneId,
        [Parameter(Mandatory)][string]$ManifestDirectory,
        [Parameter(Mandatory)][string]$CommitSha
    )

    $manifest = @(Read-CiLaneManifest -Directory $ManifestDirectory)
    Get-CiGateJobFailure -JobResult $JobResult
    foreach ($laneId in $ExpectedLaneId) {
        Get-CiLaneManifestFailure -LaneId $laneId -Manifest $manifest -CommitSha $CommitSha
    }
    foreach ($entry in $manifest | Where-Object {$_.laneId -notin $ExpectedLaneId}) {
        "Unexpected lane manifest '$( $entry.laneId )'."
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $expectedLaneId = @((Get-Content -LiteralPath $LanePath -Raw | ConvertFrom-Json).lanes | ForEach-Object {$_.id})
    $failure = @(Test-CiGateResult -JobResult (ConvertTo-CiGateJobResult -NeedsJson $env:NEEDS_JSON) `
            -ExpectedLaneId $expectedLaneId `
            -ManifestDirectory $ManifestDirectory -CommitSha $env:GITHUB_SHA)

    if ($failure.Count -gt 0) {
        $failure | ForEach-Object {Write-Output "::error title=ci-gate::$_"}
        exit 1
    }

    Write-Information "ci-gate passed: all required jobs succeeded and $( $expectedLaneId.Count ) lane manifests passed for $env:GITHUB_SHA." -InformationAction Continue
}
