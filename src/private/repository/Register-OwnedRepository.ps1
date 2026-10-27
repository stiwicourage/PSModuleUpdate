function Register-OwnedRepository {
    param([object]$Lease)
    if (@(Get-RepositoryRegistration $Lease.Name).Count) {
        Remove-Item -LiteralPath $Lease.ReceiptPath -ErrorAction Stop
        Write-PMUError 'PMU.RepositoryUnavailable' 'The random transport name already exists; it will not be overwritten.'
    }
    $parameters = Get-OwnedRepositoryRegisterParameter $Lease
    try {
        $created = @(Microsoft.PowerShell.PSResourceGet\Register-PSResourceRepository @parameters -PassThru)
    } catch {
        Write-ProviderError $_ 'PMU.RepositoryUnavailable'
    }
    Complete-OwnedRepositoryRegistration $Lease $created
}
