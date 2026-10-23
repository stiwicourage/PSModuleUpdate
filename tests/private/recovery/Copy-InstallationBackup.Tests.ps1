BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Copy-InstallationBackup' -Tag 'PMU' {
    It 'verifies a complete backup outside Modules before BackupReady is recorded' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Initialize-ControlledDirectory $operation.WorkRoot
        $operation.Journal = ConvertTo-RecoveryJournal $operation @()
        Copy-InstallationBackup $operation
        $operation.Journal.State | Should -Be 'BackupReady'
        $operation.BackupPath.StartsWith($operation.Plan.DestinationRoot) | Should -BeFalse
        Assert-FileTreeEqual $operation.Record.InstalledTree @(Get-FileTreeInventory $operation.BackupPath)
    }
}
