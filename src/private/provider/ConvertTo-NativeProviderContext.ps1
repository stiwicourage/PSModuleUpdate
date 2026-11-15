function ConvertTo-NativeProviderContext {
    param([object]$Operation)
    [pscustomobject]@{
        Root = Get-NativeProviderRoot $Operation
        Paths = $null
        CurrentUserRoot = Resolve-ModuleInstallationRoot 'CurrentUser'
    }
}
