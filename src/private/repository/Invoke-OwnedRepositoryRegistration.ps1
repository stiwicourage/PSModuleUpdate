function Invoke-OwnedRepositoryRegistration {
    param([object]$Source, [string]$Root)
    $receipt = ConvertTo-RepositoryReceipt $Source
    $path = Write-RepositoryReceipt $receipt $Root
    $lease = [pscustomobject]@{ Name = $receipt.RegistrationName; ReceiptPath = $path; Root = $Root; Receipt = $receipt; Source = $Source }
    try { Register-OwnedRepository $lease }
    catch {
        $failure = $_
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw $failure }
        try { Clear-OwnedRepositoryReceipt ([pscustomobject]@{ Path = $path; Receipt = $lease.Receipt }) }
        catch { Write-RepositoryCleanupFailure $failure }
        throw $failure
    }
    $lease
}
