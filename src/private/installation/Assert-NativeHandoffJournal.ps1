function Assert-NativeHandoffJournal {
    param(
        [object]$Operation,
        [object]$Token
    )

    $journal = Read-RecoveryJournal $Operation
    $actual = Get-NativeJournalToken $Operation $journal
    Assert-MatchingProperty $actual $Token @('TransactionId', 'State', 'SHA256') 'PMU.PlanStale'
    $journal
}
