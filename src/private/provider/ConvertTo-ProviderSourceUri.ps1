function ConvertTo-ProviderSourceUri {
    param([string]$Source)
    $uri = [uri]$Source
    if ([IO.Path]::IsPathFullyQualified($Source)) {
        $uri = [uri]::new($Source, [UriKind]::Absolute)
    }
    Assert-RepositoryUri $uri
}
