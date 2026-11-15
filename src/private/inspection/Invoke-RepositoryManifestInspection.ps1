function Invoke-RepositoryManifestInspection {
    param([object]$Operation)
    $lease = Open-RepositoryTransport (ConvertTo-PlanRepositorySource $Operation.Plan)
    $Operation.RepositoryName = $lease.Name
    $failure = $null
    try {
        Get-BoundTargetManifest $Operation
    } catch {
        $failure = $_
        Write-ManifestInspectionError $failure
    } finally {
        Close-RepositoryTransport $lease $failure
    }
}
