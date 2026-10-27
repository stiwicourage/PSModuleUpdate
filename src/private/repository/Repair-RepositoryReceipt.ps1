function Repair-RepositoryReceipt {
    param([string]$Root)
    foreach ($entry in Get-RepositoryReceiptEntry $Root) {
        if (Test-RepositoryReceiptOwnerAlive $entry.Receipt) {
            continue
        }
        Clear-OwnedRepositoryReceipt $entry
    }
}
