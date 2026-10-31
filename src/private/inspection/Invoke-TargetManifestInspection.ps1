function Invoke-TargetManifestInspection {
    param([object]$Operation)
    Initialize-ControlledDirectory $Operation.WorkRoot
    Write-InstallationPhase $Operation.Plan 'Checking'
    try {
        $result = Invoke-RepositoryManifestInspection $Operation
    } finally {
        Clear-ManifestInspection $Operation
        Write-InstallationPhase $Operation.Plan 'Completed'
    }
    $result
}
