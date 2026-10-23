BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/CiTestResultSummary.ps1')

    function Build-NUnitFile {
        param([string]$Name, [string[]]$Case)
        $path = Join-Path $TestDrive $Name
        $passed = @($Case | Where-Object { $_ -match 'result="Success"' }).Count
        $skipped = @($Case | Where-Object { $_ -match 'result="Ignored"' }).Count
        $failed = $Case.Count - $passed - $skipped
        $content = "<test-results name=`"Pester`" total=`"$($Case.Count)`" errors=`"0`" failures=`"$failed`" inconclusive=`"0`" skipped=`"$skipped`"><test-suite name=`"s`" total=`"$($Case.Count)`" passed=`"$passed`" failed=`"$failed`" skipped=`"$skipped`"><results>$($Case -join '')</results></test-suite></test-results>"
        Set-Content -LiteralPath $path -Value $content
        $path
    }

    function Build-CaseXml {
        param([string]$Name, [string]$Result)
        "<test-case name=`"$Name`" result=`"$Result`" />"
    }
}

Describe 'Get-CiTestResultSummary' -Tag 'BuildTooling' {
    It 'counts passed, failed and skipped cases and lists every skipped case by name' {
        $path = Build-NUnitFile -Name 'mixed.xml' -Case @(
            (Build-CaseXml -Name 'A.one' -Result 'Success'),
            (Build-CaseXml -Name 'A.two' -Result 'Failure'),
            (Build-CaseXml -Name 'A.three' -Result 'Ignored'),
            (Build-CaseXml -Name 'A.four' -Result 'Success')
        )

        $summary = Get-CiTestResultSummary -Path $path

        $summary.Total | Should -Be 4
        $summary.Passed | Should -Be 2
        $summary.Failed | Should -Be 1
        $summary.Skipped | Should -Be 1
        $summary.SkippedName | Should -Be @('A.three')
    }

    It 'counts inconclusive and not runnable cases as failures instead of dropping them' {
        $path = Build-NUnitFile -Name 'odd.xml' -Case @(
            (Build-CaseXml -Name 'B.one' -Result 'NotRunnable'),
            (Build-CaseXml -Name 'B.two' -Result 'Error')
        )

        (Get-CiTestResultSummary -Path $path).Failed | Should -Be 2
    }

    It 'fails when the result file does not exist so a missing report cannot pass' {
        { Get-CiTestResultSummary -Path (Join-Path $TestDrive 'missing.xml') } | Should -Throw '*not found*'
    }

    It 'reads the aggregate counts of a summary-only Nova report that has no test cases' {
        $path = Join-Path $TestDrive 'nova.xml'
        Set-Content -LiteralPath $path -Value '<test-results total="8" errors="1" failures="1" inconclusive="0" skipped="3"><test-suite name="n" total="8" passed="3" failed="2" skipped="3" /></test-results>'

        $summary = Get-CiTestResultSummary -Path $path

        $summary.Total | Should -Be 8
        $summary.Passed | Should -Be 3
        $summary.Failed | Should -Be 2
        $summary.Skipped | Should -Be 3
    }

    It 'counts inconclusive results of a summary-only report as failures' {
        $path = Join-Path $TestDrive 'nova-inconclusive.xml'
        Set-Content -LiteralPath $path -Value '<test-results total="5" errors="0" failures="0" inconclusive="2" skipped="0"><test-suite name="n" total="5" passed="3" failed="0" skipped="0" /></test-results>'

        (Get-CiTestResultSummary -Path $path).Failed | Should -Be 2
    }

    It 'rejects an empty test report instead of treating it as execution' {
        $path = Build-NUnitFile -Name 'empty.xml' -Case @()
        { Get-CiTestResultSummary -Path $path } | Should -Throw
    }

    It 'rejects invalid summary-only NUnit evidence: <Name>' -ForEach @(
        @{ Name = 'empty file'; Xml = '' }
        @{ Name = 'malformed XML'; Xml = '<test-results' }
        @{ Name = 'unrelated XML'; Xml = '<document />' }
        @{ Name = 'multiple suites'; Xml = '<test-results total="2" errors="0" failures="0" inconclusive="0" skipped="0"><test-suite total="1" passed="1" failed="0" skipped="0" /><test-suite total="1" passed="1" failed="0" skipped="0" /></test-results>' }
        @{ Name = 'multiple documents'; Xml = '<test-results /><test-results />' }
        @{ Name = 'negative counts'; Xml = '<test-results total="-1" errors="0" failures="0" inconclusive="0" skipped="0"><test-suite total="-1" passed="-1" failed="0" skipped="0" /></test-results>' }
        @{ Name = 'missing counts'; Xml = '<test-results><test-suite /></test-results>' }
        @{ Name = 'inconsistent counts'; Xml = '<test-results total="8" errors="0" failures="0" inconclusive="0" skipped="0"><test-suite total="8" passed="7" failed="0" skipped="0" /></test-results>' }
        @{ Name = 'fractional counts'; Xml = '<test-results total="1.5" errors="0" failures="0" inconclusive="0" skipped="0"><test-suite total="1.5" passed="1.5" failed="0" skipped="0" /></test-results>' }
    ) {
        $path = Join-Path $TestDrive "$Name.xml"
        Set-Content -LiteralPath $path -Value $Xml
        { Get-CiTestResultSummary -Path $path } | Should -Throw
    }
}
