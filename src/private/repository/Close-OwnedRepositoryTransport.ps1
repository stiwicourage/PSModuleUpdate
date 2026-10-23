function Close-OwnedRepositoryTransport {
    param([object]$Lease)
    $root = Resolve-RepositoryTransportRoot
    $lock = Enter-RepositoryRegistryLock $root
    try {
        $receipt = Read-RepositoryReceipt $Lease.ReceiptPath $root
        Assert-MatchingProperty $receipt $Lease.Receipt @('OperationId', 'RegistrationName', 'OwnerPid', 'OwnerStartedUtcTicks', 'UriHash') 'PMU.RepositoryRecoveryRequired'
        if ($receipt.OwnerPid -ne $PID) { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'A different operation owns this registration.' }
        Clear-OwnedRepositoryReceipt ([pscustomobject]@{ Path = $Lease.ReceiptPath; Receipt = $receipt })
    }
    finally { $lock.Dispose() }
}
