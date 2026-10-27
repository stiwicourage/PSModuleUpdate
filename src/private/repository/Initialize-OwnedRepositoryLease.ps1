function Initialize-OwnedRepositoryLease {
    param(
        [object]$Source,
        [string]$Root
    )

    $receipt = ConvertTo-RepositoryReceipt $Source
    $path = Write-RepositoryReceipt $receipt $Root
    [pscustomobject]@{
        Name = $receipt.RegistrationName
        ReceiptPath = $path
        Root = $Root
        Receipt = $receipt
        Source = $Source
    }
}
