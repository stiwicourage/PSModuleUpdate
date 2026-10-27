function Invoke-RepositoryInstallation {
    param([object]$Operation)
    $source = ConvertTo-PlanRepositorySource $Operation.Plan
    $lease = Open-RepositoryTransport $source
    $Operation.RepositoryName = $lease.Name
    $failure = $null
    try {
        Invoke-ScopedInstallation $Operation
    } catch {
        $failure = $_
        throw
    } finally {
        Close-RepositoryTransport $lease $failure
    }
}
