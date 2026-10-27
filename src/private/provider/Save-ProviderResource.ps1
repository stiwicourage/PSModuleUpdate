function Save-ProviderResource {
    param([object]$Operation)
    Assert-NativeProviderContext $Operation
    $parameters = Get-ProviderMutationParameter $Operation
    $parameters.Path = $Operation.StageRoot
    $parameters.Repository = Get-OperationRepositoryName $Operation
    try {
        $null = PowerShellGet\Save-Module @parameters
    } catch {
        Write-ProviderError $_ 'PMU.InstallationFailed'
    }
}
