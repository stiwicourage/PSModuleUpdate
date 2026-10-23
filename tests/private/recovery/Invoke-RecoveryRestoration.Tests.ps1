BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-RecoveryRestoration' -Tag 'PMU' {
    Context 'Verified restoration' {
        It 'records recovery completed after restoring previous content' {
            $operation = Initialize-PMURecoveryFixture $TestDrive
            Invoke-RecoveryRestoration $operation.Journal $operation
            $operation.Journal.State | Should -Be 'RecoveryCompleted'
        }
    }
}
