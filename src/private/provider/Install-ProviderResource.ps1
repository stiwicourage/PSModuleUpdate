function Install-ProviderResource {
    param([object]$Operation)
    $parameters = Get-ProviderMutationParameter $Operation
    $parameters.Scope = $Operation.Plan.Scope
    if ($Operation.Reinstall) { $parameters.Reinstall = $true }
    try { $null = Microsoft.PowerShell.PSResourceGet\Install-PSResource @parameters }
    catch { Write-ProviderError $_ 'PMU.InstallationFailed' }
}
