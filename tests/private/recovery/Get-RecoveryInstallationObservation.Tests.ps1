BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RecoveryInstallationObservation' -Tag 'PMU' {
    It 'derives a planning identity from a verified backup without changing disk' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $observation = Get-RecoveryInstallationObservation $operation.Journal
        $observation.FullVersion | Should -Be '2.0.0-preview.1'
        $operation.Journal.State | Should -Be 'ReplacementInProgress'
    }
}
