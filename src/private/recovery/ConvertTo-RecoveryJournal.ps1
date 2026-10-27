function ConvertTo-RecoveryJournal {
    param(
        [object]$Operation,
        [object[]]$StagedTree
    )

    $journal = [pscustomobject](ConvertTo-RecoveryJournalIdentity $Operation.Plan)
    $journal | Add-Member -NotePropertyMembers (ConvertTo-RecoveryJournalProgress $Operation $StagedTree)
    $journal
}
