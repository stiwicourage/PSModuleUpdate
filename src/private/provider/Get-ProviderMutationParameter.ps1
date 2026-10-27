function Get-ProviderMutationParameter {
    param([object]$Operation)
    $plan = $Operation.Plan
    $parameters = Get-ProviderInvocationParameter
    $parameters.Name = $plan.ModuleName
    $parameters.RequiredVersion = $plan.TargetVersion
    $parameters.AllowPrerelease = $plan.TargetIsPrerelease
    $parameters.AcceptLicense = [bool]$Operation.Consent.AcceptLicense
    $parameters.Confirm = $false
    if ($Operation.Credential) {
        $parameters.Credential = $Operation.Credential
    }
    $parameters
}
