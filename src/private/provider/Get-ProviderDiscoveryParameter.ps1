function Get-ProviderDiscoveryParameter {
    param(
        [hashtable]$Request,
        [pscredential]$Credential
    )

    $parameters = Get-ProviderInvocationParameter
    $parameters.Name = $Request.Name
    $parameters.Repository = $Request.Repository
    $parameters.Prerelease = $Request.Prerelease
    $parameters.Version = $Request.Version ? $Request.Version : '*'
    if ($Credential) {
        $parameters.Credential = $Credential
    }
    return $parameters
}
