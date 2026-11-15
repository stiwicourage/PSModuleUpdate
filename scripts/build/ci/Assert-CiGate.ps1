[CmdletBinding()]
param(
    [string]$ManifestDirectory = 'lane-manifests',
    [string]$LanePath = (Join-Path $PSScriptRoot 'CiLanes.json')
)

$script:RequiredJob = @('plan', 'quality', 'platform')
. (Join-Path $PSScriptRoot 'CiGateEvidence.ps1')

function ConvertTo-CiGateJobResult {
    [OutputType([hashtable])]
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
    [OutputType([string])]
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
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return
    }

    foreach ($file in Get-ChildItem -LiteralPath $Directory -Recurse -File -Filter 'lane-manifest.json') {
        Read-CiLaneManifestFile -File $file
    }
}

function Read-CiLaneManifestFile {
    param($File)
    try {
        $entry = Get-Content -LiteralPath $File.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        if ($entry -isnot [System.Collections.IDictionary]) {
            throw 'Manifest must be a JSON object.'
        }
        $entry['_artifactDirectory'] = $File.Directory.FullName
        $entry
    } catch {
        Get-CiInvalidManifest -Message $_.Exception.Message
    }
}

function Get-CiInvalidManifest {
    param([string]$Message)
    return @{
        laneId = '<invalid>'
        readError = $Message
    }
}

function Get-CiLaneManifestFailure {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LaneId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Manifest,
        [Parameter(Mandatory)][string]$CommitSha,
        [Parameter(Mandatory)]$RunContext
    )

    $own = @($Manifest | Where-Object { $_.laneId -eq $LaneId })
    if ($own.Count -ne 1) {
        return "Lane '$LaneId' produced $( if ($own.Count -eq 0) {'no manifest'} else {"$( $own.Count ) manifests"} )."
    }
    Get-CiLaneEntryFailure -Entry $own[0] -LaneId $LaneId -CommitSha $CommitSha -RunContext $RunContext
}

function Get-CiLaneEntryFailure {
    param($Entry, [string]$LaneId, [string]$CommitSha, $RunContext)
    if ($Entry.status -ne 'passed') {
        "Lane '$LaneId' manifest status is '$( $Entry.status )'."
    }
    if ($Entry.commitSha -ne $CommitSha) {
        "Lane '$LaneId' manifest belongs to commit '$( $Entry.commitSha )', not '$CommitSha'."
    }
    try {
        Assert-CiLaneEntryEvidence -Entry $Entry -LaneId $LaneId -RunContext $RunContext
    } catch {
        "Lane '$LaneId' evidence is invalid: $($_.Exception.Message)"
    }
}

function Assert-CiLaneEntryEvidence {
    param($Entry, [string]$LaneId, $RunContext)
    $expected = @($RunContext.lanes | Where-Object id -eq $LaneId)
    if ($expected.Count -ne 1) {
        throw 'Lane has no unique expected configuration.'
    }
    $artifactName = "pmu-ci-lane-$($RunContext.runId)-$($RunContext.runAttempt)-$LaneId"
    if ((Split-Path -Leaf $Entry._artifactDirectory) -cne $artifactName) {
        throw 'Manifest is not in its current-run named artifact directory.'
    }
    Assert-CiGateManifestEvidence -Manifest $Entry -Expected $expected[0] -RunContext $RunContext -Directory $Entry._artifactDirectory
}

function Test-CiGateResult {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$JobResult,
        [Parameter(Mandatory)][string[]]$ExpectedLaneId,
        [Parameter(Mandatory)][string]$ManifestDirectory,
        $RunContext
    )

    if (-not $RunContext) {
        $RunContext = Get-CiGateRunContext -LanePath $LanePath
    }
    Get-CiGateResultFailure -JobResult $JobResult -ExpectedLaneId $ExpectedLaneId -ManifestDirectory $ManifestDirectory -RunContext $RunContext
}

function Get-CiGateResultFailure {
    param([hashtable]$JobResult, [string[]]$ExpectedLaneId, [string]$ManifestDirectory, $RunContext)
    if (-not (Test-CiGateRunIdentity -RunContext $RunContext)) {
        return 'Gate requires nonempty current commit, run id and attempt.'
    }
    $manifest = @(Read-CiLaneManifest -Directory $ManifestDirectory)
    Get-CiGateJobFailure -JobResult $JobResult
    foreach ($laneId in $ExpectedLaneId) {
        Get-CiLaneManifestFailure -LaneId $laneId -Manifest $manifest -CommitSha $RunContext.commitSha -RunContext $RunContext
    }
    Get-CiUnexpectedManifestFailure -Manifest $manifest -ExpectedLaneId $ExpectedLaneId
}

function Test-CiGateRunIdentity {
    param($RunContext)
    foreach ($name in 'commitSha', 'runId', 'runAttempt') {
        if ([string]::IsNullOrWhiteSpace($RunContext.$name)) {
            return $false
        }
    }
    return $true
}

function Get-CiUnexpectedManifestFailure {
    param([object[]]$Manifest, [string[]]$ExpectedLaneId)
    foreach ($entry in $Manifest | Where-Object { $_.laneId -notin $ExpectedLaneId }) {
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
    $expectedLaneId = @((Get-Content -LiteralPath $LanePath -Raw | ConvertFrom-Json).lanes | ForEach-Object { $_.id })
    $failure = @(Test-CiGateResult -JobResult (ConvertTo-CiGateJobResult -NeedsJson $env:NEEDS_JSON) `
            -ExpectedLaneId $expectedLaneId `
            -ManifestDirectory $ManifestDirectory)

    if ($failure.Count -gt 0) {
        $failure | ForEach-Object { Write-Output "::error title=ci-gate::$_" }
        exit 1
    }

    Write-Information "ci-gate passed: all required jobs succeeded and $( $expectedLaneId.Count ) lane manifests passed for $env:GITHUB_SHA." -InformationAction Continue
}
