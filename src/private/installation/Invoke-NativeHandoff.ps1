function Invoke-NativeHandoff {
    param(
        [object]$Operation,
        [bool]$AlreadyInstalled
    )

    Assert-NativeParentLease $Operation
    if (-not $AlreadyInstalled -and -not $Operation.Plan.UpdateAvailable) {
        Write-PMUError 'PMU.PlanStale' 'This plan does not authorize a newer target installation.'
    }
    $snapshot = Get-NativeSelectedSnapshot $Operation $AlreadyInstalled
    Initialize-Replacement $Operation @()
    $context = ConvertTo-NativeWorkerContext $Operation $snapshot $AlreadyInstalled
    $response = Invoke-NativeWorkerProcess $Operation $context
    Assert-NativeWorkerResult $Operation $context $response
    @($Operation.Journal.StagedTree)
}
