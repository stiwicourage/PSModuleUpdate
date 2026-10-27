BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryJournalSchema' -Tag 'PMU' {
    It 'accepts legacy journals but validates an optional native transaction nonce' -Tag 'PMUNative' {
        $journal = ConvertTo-RecoveryJournal (Initialize-PMUTestOperation $TestDrive) @()
        $journal.PSObject.Properties.Remove('TransactionId')
        { Assert-RecoveryJournalSchema $journal } | Should -Not -Throw
        $journal | Add-Member TransactionId ([guid]::NewGuid().ToString('N'))
        { Assert-RecoveryJournalSchema $journal } | Should -Not -Throw
        $journal.TransactionId = 'not-a-transaction'
        { Assert-RecoveryJournalSchema $journal } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
    It 'rejects unknown journal fields rather than serializing them during recovery' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal | Add-Member ArbitraryValue 'unexpected'
        { Assert-RecoveryJournalSchema $journal } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
    It 'rejects reference and backup trees that are not arrays' {
        $journal = ConvertTo-RecoveryJournal (Initialize-PMUTestOperation $TestDrive) @()
        $journal.StagedTree = 'not-an-array'
        { Assert-RecoveryJournalSchema $journal } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
        $journal.StagedTree = @()
        $journal.BackupTree = 'not-an-array'
        { Assert-RecoveryJournalSchema $journal } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
