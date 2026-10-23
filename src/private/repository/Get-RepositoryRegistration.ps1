function Get-RepositoryRegistration {
    param([string]$Name)
    try { @(Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -ErrorAction Stop | Where-Object Name -CEQ $Name) }
    catch { Write-ProviderError $_ 'PMU.RepositoryUnavailable' }
}
