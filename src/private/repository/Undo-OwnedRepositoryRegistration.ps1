function Undo-OwnedRepositoryRegistration {
    param(
        [object]$Lease,
        [System.Management.Automation.ErrorRecord]$Failure
    )

    if (-not (Test-Path -LiteralPath $Lease.ReceiptPath -PathType Leaf)) {
        throw $Failure
    }
    try {
        Clear-OwnedRepositoryReceipt ([pscustomobject]@{
                Path = $Lease.ReceiptPath
                Receipt = $Lease.Receipt
            })
    } catch {
        Write-RepositoryCleanupFailure $Failure
    }
}
