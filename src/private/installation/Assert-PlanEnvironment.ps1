function Assert-PlanEnvironment {
    param([object]$Operation)
    $plan = $Operation.Plan
    $provider = Get-ProviderContext
    Assert-RepositoryBinding $plan $Operation.RepositoryName
    $root = Resolve-ModuleInstallationRoot $plan.Scope
    if ($root -cne $plan.DestinationRoot -or "$($provider.Version)" -cne $plan.ProviderVersion) {
        Write-PMUError 'PMU.PlanStale' 'Destination or provider context changed after planning.'
    }
    Assert-ActivePlanIdentity $Operation
}
