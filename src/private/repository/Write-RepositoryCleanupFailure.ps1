function Write-RepositoryCleanupFailure {
    param([System.Management.Automation.ErrorRecord]$Original)
    if ($Original -and $Original.FullyQualifiedErrorId -match '^PMU\.') {
        $Original.Exception.Data['PMU.RepositoryCleanupFailed'] = $true
        throw $Original
    }
    Write-PMUError 'PMU.RepositoryCleanupFailed' 'Owned transport cleanup failed. Preserve its receipt and retry after correcting the provider or permissions.'
}
