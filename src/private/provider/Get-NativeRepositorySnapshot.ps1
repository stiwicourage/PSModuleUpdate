function Get-NativeRepositorySnapshot {
    param([object]$Operation)
    Assert-NativeProviderPath $Operation (Get-NativeProviderPath)
    $repositories = @(PowerShellGet\Get-PSRepository -ErrorAction Stop)
    if ($repositories.Count -ne 1) {
        Write-PMUError 'PMU.RepositoryChanged' 'The owned native store must contain only the approved repository.'
    }
    $repository = $repositories[0]
    if ($repository.Name -ine $Operation.RepositoryName) {
        Write-PMUError 'PMU.RepositoryChanged' 'The owned native source name changed.'
    }
    if ((ConvertTo-ProviderSourceUri $repository.SourceLocation) -cne $Operation.Plan.RepositoryUri) {
        Write-PMUError 'PMU.SourceMismatch' 'The owned native repository no longer matches the approved URI.'
    }
    $repository
}
