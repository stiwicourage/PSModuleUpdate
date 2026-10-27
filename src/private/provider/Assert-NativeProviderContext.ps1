function Assert-NativeProviderContext {
    param([object]$Operation)
    $context = $Operation.PSObject.Properties['NativeContext']
    if (-not $context -or -not $context.Value) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'Native mutation requires a verified owned transaction context.'
    }
    $expected = Get-NativeProviderRoot $Operation
    if ($context.Value.Root -cne $expected) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The native provider root does not belong to this transaction.'
    }
    $paths = Get-NativeProviderPath
    Assert-NativeProviderPath $Operation $paths
    Assert-MatchingProperty $paths $context.Value.Paths @('Store', 'Settings', 'Config', 'Temporary', 'CurrentUser', 'AllUsers') 'PMU.UnsupportedProviderBehavior'
    Assert-NativeRepositoryBinding $Operation
}
