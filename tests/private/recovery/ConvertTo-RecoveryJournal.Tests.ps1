BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-RecoveryJournal' -Tag 'PMU' {
    It 'starts in Preparation without claiming any verified backup' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.State | Should -Be 'Preparation'
        $journal.BackupTree.Count | Should -Be 0
        ($journal | ConvertTo-Json -Depth 8) | Should -Not -Match 'Credential|Password'
    }
}
