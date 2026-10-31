function Write-ManifestInspectionError {
    param([Management.Automation.ErrorRecord]$Failure)
    if ($Failure.FullyQualifiedErrorId -match '^PMU\.[A-Za-z]+$') {
        throw $Failure
    }
    Write-ProviderError $Failure 'PMU.InstallationFailed'
}
