function Initialize-NativeRepository {
    param([object]$Operation)
    if (-not $Operation.Plan.RepositoryTrusted -and -not $Operation.Consent.TrustRepository) {
        Write-PMUError 'PMU.RepositoryTrustRequired' 'The native worker requires independent repository trust approval.'
    }
    if (-not (Initialize-NativeRepositoryStore $Operation)) {
        Register-NativeRepository $Operation
        $null = Initialize-NativeRepositoryStore $Operation
    }
    $null = Get-NativeRepositorySnapshot $Operation
    $null = PowerShellGet\Set-PSRepository -Name $Operation.RepositoryName -InstallationPolicy Trusted -ErrorAction Stop
    Assert-NativeRepositoryBinding $Operation
}
