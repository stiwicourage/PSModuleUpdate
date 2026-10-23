BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Restore-InstallationBackup' -Tag 'PMU' {
    It 'restores a missing installation and verifies the saved previous tree' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Remove-Item $operation.Plan.TargetInstalledPath -Recurse -Force
        Restore-InstallationBackup $operation.Journal $operation
        $operation.Journal.State | Should -Be 'RecoveryCompleted'
        Assert-FileTreeEqual $operation.Record.InstalledTree @(Get-FileTreeInventory $operation.Plan.TargetInstalledPath)
    }
    It 'preserves evidence rather than deleting a target when the backup is missing' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Remove-Item $operation.BackupPath -Recurse -Force
        { Restore-InstallationBackup $operation.Journal $operation } | Should -Throw
        Test-Path $operation.Plan.TargetInstalledPath | Should -BeTrue
        Test-Path $operation.JournalPath | Should -BeTrue
    }
}
