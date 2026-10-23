function Test-CiPhaseSucceeded {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Phase,
        [Parameter(Mandatory)][string]$Name
    )

    $match = @($Phase | Where-Object {$_.Name -eq $Name})
    return $match.Count -eq 1 -and $match[0].ExitCode -eq 0
}

function Test-CiSummaryHealthy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Summary,
        [Parameter(Mandatory)][string]$Key,
        [switch]$RequireTest
    )

    if (-not $Summary.ContainsKey($Key)) {
        return $false
    }
    $entry = $Summary[$Key]
    $hasTest = -not $RequireTest -or $entry.Total -gt 0

    return $hasTest -and $entry.Failed -eq 0
}

function Get-CiLaneStatus {
    [CmdletBinding()]
    param(
        [string[]]$Mismatch = @(),
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Phase,
        [Parameter(Mandatory)][hashtable]$Summary
    )

    $phaseHealthy = @('build', 'unit', 'integration' | Where-Object {-not (Test-CiPhaseSucceeded -Phase $Phase -Name $_)}).Count -eq 0
    $summaryHealthy = (Test-CiSummaryHealthy -Summary $Summary -Key 'unit' -RequireTest) -and (Test-CiSummaryHealthy -Summary $Summary -Key 'integration')
    $check = @(
        @($Mismatch).Count -eq 0
        $phaseHealthy
        $summaryHealthy
    )
    if ($check -notcontains $false) {
        return 'passed'
    }

    return 'failed'
}

function Build-CiLaneManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LaneId,
        [Parameter(Mandatory)][string]$CommitSha,
        [Parameter(Mandatory)]$Environment,
        [string[]]$Mismatch = @(),
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Phase,
        [Parameter(Mandatory)][hashtable]$Summary,
        [Parameter(Mandatory)][hashtable]$Module
    )

    return [ordered]@{
        laneId = $LaneId
        commitSha = $CommitSha
        status = Get-CiLaneStatus -Mismatch $Mismatch -Phase $Phase -Summary $Summary
        environment = $Environment
        mismatches = @($Mismatch)
        phases = @($Phase)
        tests = $Summary
        modules = $Module
    }
}
