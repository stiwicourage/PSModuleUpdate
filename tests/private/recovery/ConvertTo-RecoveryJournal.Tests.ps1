BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-RecoveryJournal' -Tag 'PMU' {
    It 'starts in Preparation without claiming any verified backup' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.State | Should -Be 'Preparation'
        $journal.BackupTree.Count | Should -Be 0
        ($journal | ConvertTo-Json -Depth 8) | Should -Not -Match 'Credential|Password'
    }
    It 'gives every transaction a distinct nonsecret immutable instance identifier' -Tag 'PMUNative' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $first = ConvertTo-RecoveryJournal $operation @()
        $second = ConvertTo-RecoveryJournal $operation @()
        $first.TransactionId | Should -Match '^[a-f0-9]{32}$'
        $second.TransactionId | Should -Not -BeExactly $first.TransactionId
    }
    It 'preserves flat journal property order and shallow staged-tree copying' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $tree = @([pscustomobject]@{ RelativePath = 'module.psd1' })
        $journal = ConvertTo-RecoveryJournal $operation $tree
        $fields = 'SchemaVersion TransactionId ModuleName Scope DestinationRoot ModuleGuid PreviousVersion TargetVersion TargetNumericVersion TargetPath JournalPath StageRoot StagedPath BackupPath Reinstall State RecoveryStatus StagedTree BackupTree'.Split(' ')
        @($journal.PSObject.Properties.Name) | Should -Be $fields
        $journal.PSTypeNames[0] | Should -BeExactly 'System.Management.Automation.PSCustomObject'
        $journal.ModuleGuid | Should -BeOfType ([string])
        [object]::ReferenceEquals($journal.StagedTree, $tree) | Should -BeFalse
        [object]::ReferenceEquals($journal.StagedTree[0], $tree[0]) | Should -BeTrue
    }
}
