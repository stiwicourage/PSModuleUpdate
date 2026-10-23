BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Repair-UnfinishedInstallation' -Tag 'PMU' {
    It 'repairs once and requires a fresh plan without repeating recovery' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        { Repair-UnfinishedInstallation $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
        { Repair-UnfinishedInstallation $operation } | Should -Not -Throw
        (Read-RecoveryJournal $operation).State | Should -Be 'RecoveryCompleted'
    }
}
