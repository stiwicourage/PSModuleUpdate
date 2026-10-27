function Complete-VerifiedInstallation {
    param(
        [object]$Operation,
        [object[]]$Tree,
        [bool]$AlreadyInstalled
    )

    $outcome = 'AlreadyInstalled'
    if (-not $AlreadyInstalled) {
        if (-not $Operation.Plan.UpdateAvailable) {
            Write-PMUError 'PMU.PlanStale' 'This plan does not authorize a newer target installation.'
        }
        $outcome = 'Installed'
    }
    Assert-InstalledPackage $Operation $Tree
    if ($Operation.Journal) {
        Write-RecoveryJournalState $Operation.Journal 'Completed'
    }
    $result = ConvertTo-UpdateResult $Operation.Plan $outcome 'Verified'
    $result.RecoveryStatus = $Operation.RecoveryStatus
    Clear-CompletedOperation $Operation
    $result
}
