function Get-RepositorySnapshot {
    param(
        [string]$Name,
        [uri]$ExpectedUri
    )

    Assert-RepositoryName $Name
    $repository = Get-SingleProviderRepository $Name
    $uri = Assert-RepositoryUri $repository.Uri
    if ($ExpectedUri -and $uri -ne (Assert-RepositoryUri $ExpectedUri)) {
        Write-PMUError 'PMU.RepositoryChanged' 'Repository endpoint does not match policy.'
    }
    [pscustomobject]@{
        Name = $repository.Name
        Uri = $uri
        ApiVersion = "$($repository.ApiVersion)"
        Trusted = [bool]$repository.Trusted
    }
}
