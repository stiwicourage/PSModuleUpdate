function Get-PMUFixtureProviderRoot {
    [CmdletBinding()]
    param()
    # This read-only provider-internal probe qualifies the actual 1.2.0 destination before allowing a fixture install.
    $assembly = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSResourceInfo].Assembly
    $utils = $assembly.GetType('Microsoft.PowerShell.PSResourceGet.UtilClasses.Utils')
    $method = $utils.GetMethod('GetAllInstallationPaths', [Reflection.BindingFlags]'Static,Public,NonPublic')
    $paths = @($method.Invoke($null, @($PSCmdlet, [Microsoft.PowerShell.PSResourceGet.UtilClasses.ScopeType]::CurrentUser)))
    @($paths | Where-Object { [IO.Path]::GetFileName($_) -eq 'Modules' })[0]
}
