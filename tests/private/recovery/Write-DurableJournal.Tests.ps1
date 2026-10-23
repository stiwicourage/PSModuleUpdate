BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-DurableJournal' -Tag 'PMU' {
    It 'atomically replaces JSON rather than leaving a partially appended document' {
        $journal = [pscustomobject]@{ JournalPath = "$TestDrive/journal.json"; State = 'Preparation' }
        Write-DurableJournal $journal
        $journal.State = 'Completed'
        Write-DurableJournal $journal
        (Get-Content $journal.JournalPath -Raw | ConvertFrom-Json).State | Should -Be 'Completed'
        Test-Path "$TestDrive/journal.json.new" | Should -BeFalse
    }
}
