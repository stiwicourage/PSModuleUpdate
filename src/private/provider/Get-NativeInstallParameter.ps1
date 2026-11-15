function Get-NativeInstallParameter {
    param([object]$Operation)
    $parameters = Get-ProviderMutationParameter $Operation
    $parameters.Repository = Get-OperationRepositoryName $Operation
    $parameters.Scope = $Operation.Plan.Scope
    if (Test-Path -LiteralPath $Operation.Plan.TargetInstalledPath) {
        $parameters.Force = $true
    }
    $parameters
}
