function Enter-RepositoryRegistryLock {
    param(
        [string]$Root,
        [int]$TimeoutMilliseconds = 5000
    )

    Initialize-ControlledDirectory $Root
    Enter-InstallationLock (Join-Path $Root 'registry.lock') $TimeoutMilliseconds
}
