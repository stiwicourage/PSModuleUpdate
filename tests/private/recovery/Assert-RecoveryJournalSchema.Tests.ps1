BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryJournalSchema' -Tag 'PMU' {
    It 'rejects unknown journal fields rather than serializing them during recovery' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal | Add-Member ArbitraryValue 'unexpected'
        { Assert-RecoveryJournalSchema $journal } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
