BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-RecoveryJournalProgress' -Tag 'PMU' {
    It 'initializes unverified progress without leaking operation context or aliasing the tree container' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation | Add-Member Credential 'PMUPrivacySentinel-85d3b6d1-Credential'
        $operation | Add-Member Parent 'PMUPrivacySentinel-85d3b6d1-Parent'
        $operation | Add-Member Context 'PMUPrivacySentinel-85d3b6d1-Context'
        $tree = @([pscustomobject]@{ RelativePath = 'module.psd1' })
        $progress = ConvertTo-RecoveryJournalProgress $operation $tree
        @($progress.Keys) | Should -Be 'JournalPath StageRoot StagedPath BackupPath Reinstall State RecoveryStatus StagedTree BackupTree'.Split(' ')
        $progress.State | Should -BeExactly 'Preparation'
        $progress.RecoveryStatus | Should -BeExactly 'NotRequired'
        $progress.BackupTree.Count | Should -Be 0
        [object]::ReferenceEquals($progress.StagedTree, $tree) | Should -BeFalse
        [object]::ReferenceEquals($progress.StagedTree[0], $tree[0]) | Should -BeTrue
        ($progress | ConvertTo-Json -Depth 8) | Should -Not -Match 'PMUPrivacySentinel-85d3b6d1-'
        ($progress | ConvertTo-Json -Depth 8) | Should -Not -Match '"(?:Credential|Parent|Context)"\s*:'
    }
}
