function Get-ConsumerRepositoryByUri {
    param([string]$Uri)
    try {
        $repositories = @(Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -ErrorAction Stop)
    } catch {
        Write-ProviderError $_ 'PMU.RepositoryUnavailable'
    }
    $owned = @(Get-OwnedRepositoryName)
    $selected = @($repositories | Where-Object { $_.Name -cnotin $owned -and ([uri]$_.Uri).AbsoluteUri.TrimEnd('/') -ceq $Uri })
    if ($selected.Count -gt 1) {
        Write-PMUError 'PMU.RepositoryUnavailable' 'RepositoryUri matches multiple consumer registrations.'
    }
    $selected
}
