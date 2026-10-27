function Get-NativeRepositoryParameter {
    param([object]$Operation)

    $uri = [uri]$Operation.Plan.RepositoryUri
    $location = $uri.AbsoluteUri
    if ($uri.IsFile) {
        $location = $uri.LocalPath
    }
    $parameters = @{
        Name = $Operation.RepositoryName
        SourceLocation = $location
        InstallationPolicy = 'Untrusted'
        ErrorAction = 'Stop'
    }
    if ($Operation.Credential) {
        $parameters.Credential = $Operation.Credential
    }
    $parameters
}
