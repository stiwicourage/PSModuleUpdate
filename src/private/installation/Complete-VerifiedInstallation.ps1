function Complete-VerifiedInstallation {
    param([object]$Operation, [object[]]$Tree, [bool]$AlreadyInstalled)
    $outcome = 'AlreadyInstalled'
    if ($AlreadyInstalled) { Assert-InstalledPackage $Operation $Tree }
    else {
        if (-not $Operation.Plan.UpdateAvailable) { Write-PMUError 'PMU.PlanStale' 'This plan does not authorize a newer target installation.' }
        Initialize-Replacement $Operation $Tree
        Invoke-ProviderInstallation $Operation $Tree
        $outcome = 'Installed'
    }
    $result = ConvertTo-UpdateResult $Operation.Plan $outcome 'Verified'
    $result.RecoveryStatus = $Operation.RecoveryStatus
    Clear-CompletedOperation $Operation
    $result
}
