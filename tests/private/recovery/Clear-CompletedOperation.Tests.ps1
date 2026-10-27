BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Clear-CompletedOperation' -Tag 'PMU' {
    It 'never removes the only surviving backup while recovery is unfinished' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        { Clear-CompletedOperation $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
        Test-Path $operation.BackupPath | Should -BeTrue
    }
    It 'cleans only the completed nonce-owned native stores after the original lock is reacquired' -Tag 'PMUNativeHandoff' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $root = Get-NativeProviderRoot $operation
        Initialize-ControlledDirectory $root
        [IO.File]::WriteAllText((Join-Path $root 'owned-store.xml'), 'fixture store')
        Write-RecoveryJournalState $operation.Journal 'Completed'
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        try {
            Clear-CompletedOperation $operation
            Test-Path $root | Should -BeFalse
            Test-Path $operation.Plan.TargetInstalledPath | Should -BeTrue
        } finally {
            $operation.Lock.Dispose()
        }
    }
}
