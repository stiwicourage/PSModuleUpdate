BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryPath' -Tag 'PMU' {
    It 'rejects traversal and a substituted backup symlink' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Initialize-ControlledDirectory $operation.WorkRoot
        $journal = ConvertTo-RecoveryJournal $operation @()
        $outside = Join-Path $TestDrive 'outside'
        $null = New-Item $outside -ItemType Directory
        $null = New-Item $journal.BackupPath -ItemType SymbolicLink -Target $outside
        { Assert-RecoveryPath $journal $operation } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
        Test-Path $outside | Should -BeTrue
    }
}
