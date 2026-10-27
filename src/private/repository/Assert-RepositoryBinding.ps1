function Assert-RepositoryBinding {
    param(
        [object]$Plan,
        [string]$TransportName
    )

    $name = $TransportName ? $TransportName : $Plan.RepositoryName
    if (-not $name) {
        $null = Assert-RepositoryUri ([uri]$Plan.RepositoryUri)
        return
    }
    $source = Get-RepositorySnapshot $name ([uri]$Plan.RepositoryUri)
    $expected = ConvertTo-PlanRepositorySource $Plan $name
    Assert-MatchingProperty $source $expected @('Name', 'Uri', 'ApiVersion', 'Trusted') 'PMU.RepositoryChanged'
}
