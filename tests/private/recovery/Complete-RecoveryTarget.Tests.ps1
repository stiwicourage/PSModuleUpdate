BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Complete-RecoveryTarget' -Tag 'PMU' {
    Context 'Interrupted target verification' {
        It 'does not mark an incomplete target as complete' {
            $operation = Initialize-PMURecoveryFixture $TestDrive
            Complete-RecoveryTarget $operation.Journal $operation | Should -BeFalse
            $operation.Journal.State | Should -Be 'ReplacementInProgress'
        }
    }
}
