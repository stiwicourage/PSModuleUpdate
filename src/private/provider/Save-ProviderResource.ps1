function Save-ProviderResource {
    param([object]$Operation)
    $parameters = Get-ProviderMutationParameter $Operation
    $parameters.Path = $Operation.StageRoot
    $parameters.IncludeXml = $true
    try { $null = Microsoft.PowerShell.PSResourceGet\Save-PSResource @parameters }
    catch { Write-ProviderError $_ 'PMU.InstallationFailed' }
}
