BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Write-RecoveryJournalState' -Tag 'PMU' {
    It 'durably round trips every state and refuses an invalid transition' {
        $journal = [pscustomobject]@{
            State = 'Preparation'
            JournalPath = "$TestDrive/journal.json"
            RecoveryStatus = 'NotRequired'
        }
        Write-RecoveryJournalState $journal 'Preparation'
        foreach ($state in @('BackupReady', 'ReplacementInProgress', 'Verification', 'Completed')) {
            Write-RecoveryJournalState $journal $state
            (Get-Content $journal.JournalPath -Raw | ConvertFrom-Json).State | Should -Be $state
        }
        { Write-RecoveryJournalState $journal 'ReplacementInProgress' } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
