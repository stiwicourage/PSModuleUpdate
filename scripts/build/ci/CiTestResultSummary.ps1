function Get-CiTestCaseCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Case
    )

    $skippedResult = @('Ignored', 'Skipped')
    $skipped = @($Case | Where-Object {$_.result -in $skippedResult})
    $passed = @($Case | Where-Object {$_.result -eq 'Success'})

    return @{
        Total = $Case.Count
        Passed = $passed.Count
        Skipped = $skipped.Count
        SkippedName = @($skipped | ForEach-Object {$_.name})
    }
}

function Get-CiAggregateCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][xml]$Document
    )

    $suite = $Document.SelectNodes('//test-suite') | Select-Object -First 1
    $passed = if ($suite -and $suite.passed) {[int]$suite.passed} else {0}

    return @{
        Total = [int]$Document.'test-results'.total
        Passed = $passed
        Skipped = [int]$Document.'test-results'.skipped
        SkippedName = @()
    }
}

function Get-CiTestResultSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Test result file '$Path' was not found."
    }

    [xml]$document = Get-Content -LiteralPath $Path -Raw
    $case = @($document.SelectNodes('//test-case'))
    $count = if ($case.Count -gt 0) {Get-CiTestCaseCount -Case $case} else {Get-CiAggregateCount -Document $document}

    return [pscustomobject][ordered]@{
        Path = $Path
        Total = $count.Total
        Passed = $count.Passed
        Failed = $count.Total - $count.Passed - $count.Skipped
        Skipped = $count.Skipped
        SkippedName = $count.SkippedName
    }
}
