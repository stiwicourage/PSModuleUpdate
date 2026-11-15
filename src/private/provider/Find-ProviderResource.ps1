function Find-ProviderResource {
    param(
        [hashtable]$Request,
        [pscredential]$Credential
    )

    $parameters = Get-ProviderDiscoveryParameter $Request $Credential
    try {
        Microsoft.PowerShell.PSResourceGet\Find-PSResource @parameters
    } catch {
        if (($_.FullyQualifiedErrorId -split ',', 2)[0] -ceq 'PackageNotFound') {
            Write-PMUError 'PMU.PackageNotFound' 'The requested package was not found in the selected repository.'
        }
        Write-ProviderError $_ 'PMU.DiscoveryFailed'
    }
}
