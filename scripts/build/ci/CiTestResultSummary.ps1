function Get-CiNUnitCount {
    param(
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][string]$Name
    )

    $value = $Node.GetAttribute($Name)
    if ($value -notmatch '^\d+$') {
        throw "Invalid or missing NUnit count '$Name'."
    }
    $number = 0
    if (-not [int]::TryParse($value, [ref]$number)) {
        throw "NUnit count '$Name' is out of range."
    }
    return $number
}

function Get-CiAggregateCount {
    param([Parameter(Mandatory)][xml]$Document)

    $root = $Document.DocumentElement
    if ($root.LocalName -ne 'test-results') {
        throw 'Expected an NUnit test-results document.'
    }
    $suite = @($root.SelectNodes('./test-suite'))
    if ($suite.Count -ne 1) {
        throw 'Expected one NUnit root test-suite.'
    }
    $count = @{}
    foreach ($name in 'total', 'errors', 'failures', 'inconclusive', 'skipped') {
        $count[$name] = Get-CiNUnitCount -Node $root -Name $name
    }
    $count.passed = Get-CiNUnitCount -Node $suite[0] -Name 'passed'
    Assert-CiNUnitCount -Count $count -Suite $suite[0]
    return $count
}

function Assert-CiNUnitCount {
    param(
        [Parameter(Mandatory)][hashtable]$Count,
        [Parameter(Mandatory)]$Suite
    )

    $failed = $Count.errors + $Count.failures
    if ($Count.total -le 0) {
        throw 'NUnit report contains no tests.'
    }
    if ($Count.total -ne ($Count.passed + $failed + $Count.inconclusive + $Count.skipped)) {
        throw 'Inconsistent NUnit totals.'
    }
    foreach ($name in 'total', 'skipped') {
        if ((Get-CiNUnitCount -Node $Suite -Name $name) -ne $Count[$name]) {
            throw "Inconsistent NUnit suite '$name'."
        }
    }
    if ((Get-CiNUnitCount -Node $Suite -Name 'failed') -ne $failed) {
        throw 'Inconsistent NUnit failure count.'
    }
    if ($Suite.HasAttribute('inconclusive') -and (Get-CiNUnitCount -Node $Suite -Name 'inconclusive') -ne $Count.inconclusive) {
        throw 'Inconsistent NUnit inconclusive count.'
    }
}

function Get-CiTestCaseCount {
    param([Parameter(Mandatory)][object[]]$Case)

    $skipped = @($Case | Where-Object { $_.result -in 'Ignored', 'Skipped' })
    return @{
        Total = $Case.Count
        Passed = @($Case | Where-Object result -eq 'Success').Count
        Skipped = $skipped.Count
        SkippedName = @($skipped | ForEach-Object { $_.name })
    }
}

function Get-CiTestResultSummary {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Test result file '$Path' was not found."
    }
    [xml]$document = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    $count = Get-CiAggregateCount -Document $document
    $summary = [ordered]@{
        Path = Split-Path -Leaf $Path
        Total = $count.total
        Passed = $count.passed
        Failed = $count.errors + $count.failures + $count.inconclusive
        Skipped = $count.skipped
        SkippedName = @()
    }
    $summary.SkippedName = @(Get-CiDetailedSkippedName -Document $document -Summary $summary)
    return [pscustomobject]$summary
}

function Get-CiDetailedSkippedName {
    param(
        [Parameter(Mandatory)][xml]$Document,
        [Parameter(Mandatory)]$Summary
    )

    $cases = @($Document.SelectNodes('//test-case'))
    if ($cases.Count -eq 0) {
        return
    }
    $count = Get-CiTestCaseCount -Case $cases
    foreach ($name in 'Total', 'Passed', 'Skipped') {
        if ($count[$name] -ne $Summary[$name]) {
            throw "NUnit case detail disagrees with '$name'."
        }
    }
    return $count.SkippedName
}
