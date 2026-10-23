function Complete-OwnedRepositoryBinding {
    param([object]$Lease, [object]$Registration)
    if ($Lease.Receipt.ApiVersion -ne 'Unknown') { Assert-OwnedRepositoryConfiguration $Registration $Lease.Receipt; return }
    $bound = $Lease.Receipt.PSObject.Copy()
    $bound.ApiVersion = "$($Registration.ApiVersion)"
    if ($bound.ApiVersion -eq 'Unknown') { Write-PMUError 'PMU.RepositoryUnavailable' 'The provider did not resolve its repository API.' }
    Assert-RepositoryReceipt $bound
    Assert-OwnedRepositoryConfiguration $Registration $bound
    $Lease.Receipt = $bound
    Write-BoundRepositoryReceipt $Lease
    $Lease.Source.ApiVersion = $bound.ApiVersion
}
