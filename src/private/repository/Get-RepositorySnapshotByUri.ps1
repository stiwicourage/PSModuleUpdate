function Get-RepositorySnapshotByUri {
    param([uri]$RepositoryUri, [uri]$ExpectedUri)
    $uri = Assert-RepositoryUri $RepositoryUri
    if ($ExpectedUri -and $uri -cne (Assert-RepositoryUri $ExpectedUri)) { Write-PMUError 'PMU.RepositoryChanged' 'Repository endpoint does not match policy.' }
    try { $repositories = @(Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -ErrorAction Stop) }
    catch { Write-ProviderError $_ 'PMU.RepositoryUnavailable' }
    $owned = @(Get-OwnedRepositoryName)
    $selected = @($repositories | Where-Object { $_.Name -cnotin $owned -and ([uri]$_.Uri).AbsoluteUri.TrimEnd('/') -ceq $uri })
    if ($selected.Count -gt 1) { Write-PMUError 'PMU.RepositoryUnavailable' 'RepositoryUri matches multiple consumer registrations.' }
    if (-not $selected.Count) { return [pscustomobject]@{ Name = $null; Uri = $uri; ApiVersion = 'Unknown'; Trusted = $false } }
    Get-RepositorySnapshot $selected[0].Name ([uri]$uri)
}
