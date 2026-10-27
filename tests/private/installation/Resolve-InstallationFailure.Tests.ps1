BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-InstallationFailure' -Tag 'PMU' {
    It 'reports both installation and rollback failure while retaining evidence' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Mock Restore-InstallationBackup { throw 'fixture recovery failure' }
        try {
            throw 'fixture original failure'
        } catch {
            $failure = $_
        }
        { Resolve-InstallationFailure $operation $failure } | Should -Throw -ErrorId 'PMU.RollbackFailed'
        (Read-RecoveryJournal $operation).State | Should -Be 'RecoveryRequired'
        Test-Path $operation.BackupPath | Should -BeTrue
    }
}
