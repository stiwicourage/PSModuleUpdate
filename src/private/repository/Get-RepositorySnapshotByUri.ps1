function Get-RepositorySnapshotByUri {
    param(
        [uri]$RepositoryUri,
        [uri]$ExpectedUri
    )

    $uri = Assert-RepositoryUri $RepositoryUri
    if ($ExpectedUri -and $uri -cne (Assert-RepositoryUri $ExpectedUri)) {
        Write-PMUError 'PMU.RepositoryChanged' 'Repository endpoint does not match policy.'
    }
    $selected = @(Get-ConsumerRepositoryByUri $uri)
    if (-not $selected.Count) {
        return [pscustomobject]@{
            Name = $null
            Uri = $uri
            ApiVersion = 'Unknown'
            Trusted = $false
        }
    }
    Get-RepositorySnapshot $selected[0].Name ([uri]$uri)
}
