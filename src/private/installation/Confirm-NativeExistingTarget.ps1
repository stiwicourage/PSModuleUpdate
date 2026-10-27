function Confirm-NativeExistingTarget {
    param(
        [object]$Operation,
        [object[]]$Tree
    )

    Assert-InstalledPackage $Operation $Tree
    Write-RecoveryJournalState $Operation.Journal 'ReplacementInProgress'
    Write-RecoveryJournalState $Operation.Journal 'Verification'
}
