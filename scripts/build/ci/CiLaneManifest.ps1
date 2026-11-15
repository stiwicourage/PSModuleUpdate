function Test-CiPhaseSucceeded {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Phase,
        [Parameter(Mandatory)][string]$Name
    )

    $match = @($Phase | Where-Object { $_.Name -eq $Name })
    return $match.Count -eq 1 -and $match[0].ExitCode -eq 0
}

function Test-CiSummaryHealthy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Summary,
        [Parameter(Mandatory)][string]$Key
    )

    if (-not $Summary.ContainsKey($Key)) {
        return $false
    }
    $entry = $Summary[$Key]
    $hasTest = $entry.Total -gt 0 -and $entry.Passed -gt 0
    $consistent = $entry.Total -eq ($entry.Passed + $entry.Failed + $entry.Skipped)

    return $hasTest -and $consistent -and $entry.Failed -eq 0
}

function Get-CiLaneStatus {
    [CmdletBinding()]
    param(
        [string[]]$Mismatch = @(),
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Phase,
        [Parameter(Mandatory)][hashtable]$Summary
    )

    $check = @(Get-CiLaneHealthCheck -Mismatch $Mismatch -Phase $Phase -Summary $Summary)
    if ($check -notcontains $false) {
        return 'passed'
    }

    return 'failed'
}

function Get-CiLaneHealthCheck {
    param([string[]]$Mismatch, [object[]]$Phase, [hashtable]$Summary)
    $phaseHealthy = @('build', 'unit', 'integration' | Where-Object { -not (Test-CiPhaseSucceeded -Phase $Phase -Name $_) }).Count -eq 0
    $summaryHealthy = (Test-CiSummaryHealthy -Summary $Summary -Key 'unit') -and (Test-CiSummaryHealthy -Summary $Summary -Key 'integration')
    return @(
        @($Mismatch).Count -eq 0
        $phaseHealthy
        $summaryHealthy
    )
}

function Build-CiLaneManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Run,
        [Parameter(Mandatory)][hashtable]$Module
    )

    $manifest = Get-CiLaneManifestIdentity -Run $Run
    $manifest['mismatches'] = @($Run.Mismatch)
    $manifest['phases'] = @($Run.Phase)
    $manifest['tests'] = $Run.Summary
    $manifest['modules'] = $Module
    return $manifest
}

function Get-CiLaneManifestIdentity {
    # Run is the existing lane execution record: Lane, Identity, Actual, Mismatch, Phase and Summary.
    param([hashtable]$Run)
    return [ordered]@{
        laneId = $Run.Lane.id
        commitSha = $Run.Identity.commitSha
        status = Get-CiLaneStatus -Mismatch $Run.Mismatch -Phase $Run.Phase -Summary $Run.Summary
        environment = $Run.Actual
    }
}
