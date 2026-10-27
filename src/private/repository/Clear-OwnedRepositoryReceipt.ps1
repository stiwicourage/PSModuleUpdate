function Clear-OwnedRepositoryReceipt {
    param([object]$Entry)
    $registered = @(Get-RepositoryRegistration $Entry.Receipt.RegistrationName)
    if ($registered.Count -gt 1) {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Owned registration is ambiguous.'
    }
    if ($registered.Count) {
        Assert-OwnedRepositoryConfiguration $registered[0] $Entry.Receipt
        try {
            Microsoft.PowerShell.PSResourceGet\Unregister-PSResourceRepository -Name $Entry.Receipt.RegistrationName -Confirm:$false -ErrorAction Stop
        } catch {
            Write-ProviderError $_ 'PMU.RepositoryCleanupFailed'
        }
    }
    Remove-Item -LiteralPath (Assert-SafePath $Entry.Path) -ErrorAction Stop
}
