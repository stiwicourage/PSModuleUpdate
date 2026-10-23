BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Clear-CompletedOperation' -Tag 'PMU' {
    It 'never removes the only surviving backup while recovery is unfinished' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        { Clear-CompletedOperation $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
        Test-Path $operation.BackupPath | Should -BeTrue
    }
}
