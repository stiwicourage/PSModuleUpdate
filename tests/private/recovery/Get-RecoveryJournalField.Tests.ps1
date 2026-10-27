# Nonce/legacy schema behavior spans the field selector and validator.
# Assert-RecoveryJournalSchema.Tests.ps1 owns the behavioral cases.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RecoveryJournalField' -Tag 'PMUNative' {
    It 'includes only the optional validated nonce in addition to the legacy fields' {
        $journal = ConvertTo-RecoveryJournal (Initialize-PMUTestOperation $TestDrive) @()
        Get-RecoveryJournalField $journal | Should -Contain 'TransactionId'
        $journal.PSObject.Properties.Remove('TransactionId')
        Get-RecoveryJournalField $journal | Should -Not -Contain 'TransactionId'
    }
}
