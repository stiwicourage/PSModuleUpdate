function Close-RepositoryTransport {
    param([object]$Lease, [System.Management.Automation.ErrorRecord]$Original)
    if (-not $Lease.ReceiptPath) { return }
    try { Close-OwnedRepositoryTransport $Lease }
    catch { Write-RepositoryCleanupFailure $Original }
}
