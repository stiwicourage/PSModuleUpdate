function Read-RepositoryReceipt {
    param(
        [string]$Path,
        [string]$Root
    )

    $safe = Get-BoundedRepositoryReceiptPath $Path $Root
    try {
        $receipt = Get-Content -LiteralPath $safe -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt is unreadable or incomplete.'
    }
    Assert-RepositoryReceipt $receipt
    if ([IO.Path]::GetFileName($safe) -cne "$($receipt.OperationId).json") {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt name does not match its operation.'
    }
    $receipt
}
