function Get-OwnedRepositoryName {
    $root = Resolve-RepositoryTransportRoot
    foreach ($entry in Get-RepositoryReceiptEntry $root) {
        $registered = @(Get-RepositoryRegistration $entry.Receipt.RegistrationName)
        if (-not $registered.Count) { continue }
        Assert-OwnedRepositoryConfiguration $registered[0] $entry.Receipt
        $entry.Receipt.RegistrationName
    }
}
