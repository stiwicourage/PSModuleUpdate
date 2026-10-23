function Register-OwnedRepository {
    param([object]$Lease)
    if (@(Get-RepositoryRegistration $Lease.Name).Count) {
        Remove-Item -LiteralPath $Lease.ReceiptPath -ErrorAction Stop
        Write-PMUError 'PMU.RepositoryUnavailable' 'The random transport name already exists; it will not be overwritten.'
    }
    $parameters = @{ Name = $Lease.Name; Uri = $Lease.Source.Uri; Priority = 50; ErrorAction = 'Stop' }
    if ($Lease.Receipt.ApiVersion -ne 'Unknown') { $parameters.ApiVersion = $Lease.Receipt.ApiVersion }
    try {
        $created = @(Microsoft.PowerShell.PSResourceGet\Register-PSResourceRepository @parameters -PassThru)
    }
    catch { Write-ProviderError $_ 'PMU.RepositoryUnavailable' }
    if ($created.Count -ne 1) { Write-PMUError 'PMU.RepositoryUnavailable' 'Transport registration did not return one provider identity.' }
    Complete-OwnedRepositoryBinding $Lease $created[0]
    $registered = @(Get-RepositoryRegistration $Lease.Name)
    if ($registered.Count -ne 1) { Write-PMUError 'PMU.RepositoryUnavailable' 'Transport registration could not be verified.' }
    Assert-OwnedRepositoryConfiguration $registered[0] $Lease.Receipt
}
