function Assert-PMUNativeFixtureStore {
    param(
        [string]$Root,
        [string]$ExpectedDestination
    )

    Import-Module (Join-Path $PSHOME 'Modules/PackageManagement/PackageManagement.psd1') -RequiredVersion 1.4.8.1
    Import-Module (Join-Path $PSHOME 'Modules/PowerShellGet/PowerShellGet.psd1') -RequiredVersion 2.2.5
    $paths = & (Get-Module PSModuleUpdate) { Assert-NativeNuGetProvider
        Get-NativeProviderPath }
    $prefix = [IO.Path]::GetFullPath((Join-Path $Root 'home')) + [IO.Path]::DirectorySeparatorChar
    foreach ($path in @($paths.Store, $paths.Settings, $paths.Config, $paths.Temporary)) {
        if (-not [IO.Path]::GetFullPath($path).StartsWith($prefix, [StringComparison]::Ordinal)) {
            throw 'The fixture refuses a native writer outside its owned home.'
        }
    }
    if ($paths.CurrentUser -cne $ExpectedDestination) {
        throw 'Native bootstrap changed the disposable destination.'
    }
}
