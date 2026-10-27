function Assert-RecoveryTransactionId {
    param([object]$TransactionId)
    $parsed = [guid]::Empty
    if ($TransactionId -isnot [string] -or -not [guid]::TryParseExact($TransactionId, 'N', [ref]$parsed)) {
        Write-PMUError 'PMU.RecoveryRequired' 'The recovery transaction identifier is invalid.'
    }
}
