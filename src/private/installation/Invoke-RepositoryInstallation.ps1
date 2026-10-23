function Invoke-RepositoryInstallation {
    param([object]$Operation)
    $plan = $Operation.Plan
    $source = [pscustomobject]@{ Name = $plan.RepositoryName; Uri = $plan.RepositoryUri; ApiVersion = $plan.RepositoryApiVersion; Trusted = $plan.RepositoryTrusted }
    $lease = Open-RepositoryTransport $source
    $Operation.RepositoryName = $lease.Name
    $failure = $null
    try { Invoke-ScopedInstallation $Operation }
    catch { $failure = $_; throw }
    finally { Close-RepositoryTransport $lease $failure }
}
