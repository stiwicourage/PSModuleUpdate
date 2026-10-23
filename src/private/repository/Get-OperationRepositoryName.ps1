function Get-OperationRepositoryName {
    param([object]$Operation)
    if ($Operation.RepositoryName) { return $Operation.RepositoryName }
    $Operation.Plan.RepositoryName
}
