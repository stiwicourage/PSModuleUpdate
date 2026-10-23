function Find-ProviderResource {
    param([hashtable]$Request, [pscredential]$Credential)
    $parameters = @{ Name = $Request.Name; Repository = $Request.Repository; Prerelease = $Request.Prerelease; ErrorAction = 'Stop'; WarningAction = 'SilentlyContinue'; Verbose = $false; Debug = $false }
    $parameters.Version = '*'
    if ($Request.Version) { $parameters.Version = $Request.Version }
    if ($Credential) { $parameters.Credential = $Credential }
    try { Microsoft.PowerShell.PSResourceGet\Find-PSResource @parameters }
    catch { Write-ProviderError $_ 'PMU.DiscoveryFailed' }
}
