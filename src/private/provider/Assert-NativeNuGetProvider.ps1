function Assert-NativeNuGetProvider {
    $provider = Get-PackageProvider -Name NuGet -ErrorAction Stop
    if ($provider.Version -ne [version]'3.0.0.1') {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The qualified NuGet provider is unavailable; PMU does not bootstrap providers.'
    }
    $root = (Join-Path $PSHOME 'Modules/PackageManagement') + [IO.Path]::DirectorySeparatorChar
    if (-not $provider.ProviderPath.StartsWith($root, [StringComparison]::Ordinal)) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The NuGet provider is not the qualified runtime-bundled binary.'
    }
}
