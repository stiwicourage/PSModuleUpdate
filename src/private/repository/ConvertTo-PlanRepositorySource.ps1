function ConvertTo-PlanRepositorySource {
    param(
        [object]$Plan,
        [string]$TransportName
    )

    [pscustomobject]@{
        Name = $TransportName ? $TransportName : $Plan.RepositoryName
        Uri = $Plan.RepositoryUri
        ApiVersion = $Plan.RepositoryApiVersion
        Trusted = $Plan.RepositoryTrusted
    }
}
