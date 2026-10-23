function Assert-RepositoryBinding {
    param([object]$Plan, [string]$TransportName)
    $name = $Plan.RepositoryName
    if ($TransportName) { $name = $TransportName }
    if (-not $name) { $null = Assert-RepositoryUri ([uri]$Plan.RepositoryUri); return }
    $source = Get-RepositorySnapshot $name ([uri]$Plan.RepositoryUri)
    $expected = [pscustomobject]@{
        Name = $name; Uri = $Plan.RepositoryUri
        ApiVersion = $Plan.RepositoryApiVersion; Trusted = $Plan.RepositoryTrusted
    }
    Assert-MatchingProperty $source $expected @('Name', 'Uri', 'ApiVersion', 'Trusted') 'PMU.RepositoryChanged'
}
