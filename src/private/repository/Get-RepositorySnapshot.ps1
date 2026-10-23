function Get-RepositorySnapshot {
    param([string]$Name, [uri]$ExpectedUri)
    Assert-RepositoryName $Name
    try { $repositories = @(Microsoft.PowerShell.PSResourceGet\Get-PSResourceRepository -Name $Name -ErrorAction Stop) }
    catch { Write-ProviderError $_ 'PMU.RepositoryUnavailable' }
    if ($repositories.Count -ne 1) { Write-PMUError 'PMU.RepositoryUnavailable' 'Exactly one registered repository is required.' }
    $repository = $repositories[0]
    $uri = Assert-RepositoryUri $repository.Uri
    if ($ExpectedUri -and $uri -ne (Assert-RepositoryUri $ExpectedUri)) { Write-PMUError 'PMU.RepositoryChanged' 'Repository endpoint does not match policy.' }
    [pscustomobject]@{ Name = $repository.Name; Uri = $uri; ApiVersion = "$($repository.ApiVersion)"; Trusted = [bool]$repository.Trusted }
}
