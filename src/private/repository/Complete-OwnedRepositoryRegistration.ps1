function Complete-OwnedRepositoryRegistration {
    param(
        [object]$Lease,
        [object[]]$Created
    )
    if ($Created.Count -ne 1) {
        Write-PMUError 'PMU.RepositoryUnavailable' 'Transport registration did not return one provider identity.'
    }
    Complete-OwnedRepositoryBinding $Lease $Created[0]
    $registered = @(Get-RepositoryRegistration $Lease.Name)
    if ($registered.Count -ne 1) {
        Write-PMUError 'PMU.RepositoryUnavailable' 'Transport registration could not be verified.'
    }
    Assert-OwnedRepositoryConfiguration $registered[0] $Lease.Receipt
}
