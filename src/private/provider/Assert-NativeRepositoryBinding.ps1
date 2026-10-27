function Assert-NativeRepositoryBinding {
    param([object]$Operation)
    $repository = Get-NativeRepositorySnapshot $Operation
    if ($repository.InstallationPolicy -cne 'Trusted') {
        Write-PMUError 'PMU.RepositoryChanged' 'The independently approved owned trust policy changed.'
    }
}
