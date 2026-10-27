function Assert-NativeResultOwnership {
    param(
        [object]$Operation,
        [object]$Context,
        [object]$Result
    )

    if (-not $Result) {
        Write-PMUError 'PMU.RecoveryRequired' 'The native worker returned no owned result. Pending state was preserved.'
    }
    $token = $Result.Token
    if (-not $token) {
        $token = $Context.Token
    }
    Assert-MatchingProperty $token $Context.Token @('TransactionId') 'PMU.PlanStale'
    $journal = Assert-NativeHandoffJournal $Operation $token
    if (-not $Result.Token) {
        Write-NativeWorkerError $Result
    }
    $journal
}
