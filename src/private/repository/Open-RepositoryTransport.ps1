function Open-RepositoryTransport {
    param([object]$Source, [int]$TimeoutMilliseconds = 5000)
    $null = Assert-RepositoryUri ([uri]$Source.Uri)
    if ($Source.Name) { return [pscustomobject]@{ Name = $Source.Name; ReceiptPath = $null } }
    $root = Resolve-RepositoryTransportRoot
    $lock = Enter-RepositoryRegistryLock $root $TimeoutMilliseconds
    try {
        Repair-RepositoryReceipt $root
        Invoke-OwnedRepositoryRegistration $Source $root
    }
    finally { $lock.Dispose() }
}
