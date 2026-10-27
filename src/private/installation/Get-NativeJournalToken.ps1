function Get-NativeJournalToken {
    param(
        [object]$Operation,
        [object]$Journal
    )

    if (-not $Journal) {
        $Journal = Read-RecoveryJournal $Operation
    }
    if (-not $Journal -or -not $Journal.PSObject.Properties['TransactionId']) {
        Write-PMUError 'PMU.PlanStale' 'A native handoff requires its original transaction instance.'
    }
    [pscustomobject]@{
        TransactionId = $Journal.TransactionId
        State = $Journal.State
        SHA256 = (Get-FileHash -LiteralPath $Operation.JournalPath -Algorithm SHA256).Hash
    }
}
