function Get-ProviderMutationParameter {
    param([object]$Operation)
    $plan = $Operation.Plan
    $parameters = @{
        Name = $plan.ModuleName; Version = "[$($plan.TargetVersion)]"; Repository = Get-OperationRepositoryName $Operation
        Prerelease = $plan.TargetIsPrerelease; TrustRepository = [bool]$Operation.Consent.TrustRepository
        AcceptLicense = [bool]$Operation.Consent.AcceptLicense; Quiet = $true; Confirm = $false
        ErrorAction = 'Stop'; WarningAction = 'SilentlyContinue'; Verbose = $false; Debug = $false
    }
    if ($Operation.Credential) { $parameters.Credential = $Operation.Credential }
    $parameters
}
