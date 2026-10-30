function Find-ProviderResource {
    param(
        [hashtable]$Request,
        [pscredential]$Credential
    )

    $parameters = Get-ProviderDiscoveryParameter $Request $Credential
    try {
        Microsoft.PowerShell.PSResourceGet\Find-PSResource @parameters
    } catch {
        Write-ProviderError $_ 'PMU.DiscoveryFailed'
    }
}
