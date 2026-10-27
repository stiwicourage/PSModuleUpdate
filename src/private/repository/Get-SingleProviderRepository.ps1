function Get-SingleProviderRepository {
    param([string]$Name)

    try {
        $repositories = @(Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -Name $Name -ErrorAction Stop)
    } catch {
        Write-ProviderError $_ 'PMU.RepositoryUnavailable'
    }
    if ($repositories.Count -ne 1) {
        Write-PMUError 'PMU.RepositoryUnavailable' 'Exactly one registered repository is required.'
    }
    $repositories[0]
}
