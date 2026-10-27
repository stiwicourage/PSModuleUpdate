function Get-NativeUpdateParameter {
    param([object]$Operation)
    $parameters = Get-ProviderMutationParameter $Operation
    $plan = $Operation.Plan
    if (Test-SameBaseStablePromotion $plan) {
        $null = $parameters.Remove('RequiredVersion')
        $null = $parameters.Remove('AllowPrerelease')
        $parameters.MaximumVersion = $plan.TargetVersion
    }
    $parameters.Scope = $plan.Scope
    $parameters
}
