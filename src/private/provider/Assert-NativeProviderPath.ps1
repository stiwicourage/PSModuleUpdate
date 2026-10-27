function Assert-NativeProviderPath {
    param(
        [object]$Operation,
        [object]$Paths
    )

    $root = (Assert-SafePath $Operation.NativeContext.Root) + [IO.Path]::DirectorySeparatorChar
    foreach ($field in @('Store', 'Settings', 'Config', 'Temporary')) {
        if (-not (Assert-SafePath $Paths.$field).StartsWith($root, [StringComparison]::Ordinal)) {
            Write-PMUError 'PMU.UnsupportedProviderBehavior' 'A native provider store or temporary path is outside its owned root.'
        }
    }
    if ($Paths.($Operation.Plan.Scope) -cne $Operation.Plan.DestinationRoot -or
        $Paths.CurrentUser -cne $Operation.NativeContext.CurrentUserRoot) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'Native isolation changed the approved installation destination.'
    }
}
