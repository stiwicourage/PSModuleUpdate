function Initialize-NativeProvider {
    param([object]$Operation)
    Import-Module (Join-Path $PSHOME 'Modules/PackageManagement/PackageManagement.psd1') -RequiredVersion 1.4.8.1 -ErrorAction Stop
    Import-Module (Join-Path $PSHOME 'Modules/PowerShellGet/PowerShellGet.psd1') -RequiredVersion 2.2.5 -ErrorAction Stop
    $paths = Get-NativeProviderPath
    Assert-NativeProviderPath $Operation $paths
    $Operation.NativeContext.Paths = $paths
    Assert-NativeNuGetProvider
    Initialize-NativeRepository $Operation
    Assert-NativeProviderContext $Operation
}
