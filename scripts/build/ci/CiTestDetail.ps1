function Read-CiTestDetail {
    param([Parameter(Mandatory)][string]$Path)

    $file = $null
    foreach ($raw in Get-Content -LiteralPath $Path -ErrorAction Stop) {
        $line = $raw -replace '\x1b\[[0-?]*[ -/]*[@-~]', ''
        if ($line -match "^Running tests from '.*[/\\](tests[/\\].+\.Tests\.ps1)'$") {
            $file = $Matches[1].Replace('\', '/')
        }
        ConvertFrom-CiTestDetailLine -Line $line -File $file
    }
}

function ConvertFrom-CiTestDetailLine {
    param(
        [string]$Line,
        [AllowNull()][string]$File
    )

    if ($Line -notmatch '^\s+\[([+!\-?])\] (.+) \d+(?:\.\d+)?(?:ms|s) \(') {
        return
    }
    if (-not $File) {
        throw 'Test detail has no owning file.'
    }
    $result = @{
        '+' = 'Passed'
        '!' = 'Skipped'
        '-' = 'Failed'
        '?' = 'Inconclusive'
    }[$Matches[1]]
    return [pscustomobject]@{
        File = $File
        Name = $Matches[2]
        Result = $result
    }
}

function Get-CiAllowedSkip {
    param([Parameter(Mandatory)][string]$OperatingSystem)

    $policy = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'CiSkipPolicy.json') -Raw | ConvertFrom-Json
    return @($policy | Where-Object { $OperatingSystem -in $_.operatingSystems })
}

function Assert-CiAllowedSkip {
    param(
        [Parameter(Mandatory)][object[]]$Detail,
        [Parameter(Mandatory)][string]$OperatingSystem
    )

    $policy = @(Get-CiAllowedSkip -OperatingSystem $OperatingSystem)
    foreach ($test in $Detail | Where-Object Result -eq 'Skipped') {
        $allowed = @($policy | Where-Object { $_.file -ceq $test.File -and $_.name -ceq $test.Name })
        if ($allowed.Count -ne 1) {
            throw "Unexpected skip '$($test.File): $($test.Name)' on $OperatingSystem."
        }
    }
}

function Assert-CiTestDetail {
    param(
        [Parameter(Mandatory)]$Summary,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Detail,
        [Parameter(Mandatory)][string]$OperatingSystem
    )

    if ($Detail.Count -ne $Summary.Total) {
        throw 'Incomplete detailed test evidence: total differs from NUnit.'
    }
    foreach ($name in 'Passed', 'Skipped') {
        if (@($Detail | Where-Object Result -eq $name).Count -ne $Summary.$name) {
            throw "Detailed '$name' count differs from NUnit."
        }
    }
    $failed = @($Detail | Where-Object { $_.Result -in 'Failed', 'Inconclusive' }).Count
    if ($failed -ne $Summary.Failed) {
        throw 'Detailed failure count differs from NUnit.'
    }
    Assert-CiAllowedSkip -Detail $Detail -OperatingSystem $OperatingSystem
}
