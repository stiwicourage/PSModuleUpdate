function Assert-NativeWorkerResult {
    param(
        [object]$Operation,
        [object]$Context,
        [object]$Result
    )

    Assert-NativeParentLease $Operation
    $Operation.Journal = Assert-NativeResultOwnership $Operation $Context $Result
    if (-not $Result.Success) {
        Write-NativeWorkerError $Result
    }
    if ($Operation.Journal.State -cne 'Verification') {
        Write-PMUError 'PMU.PlanStale' 'The native verification phase was superseded.'
    }
}
