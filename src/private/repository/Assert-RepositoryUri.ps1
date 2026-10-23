function Assert-RepositoryUri {
    param([uri]$Uri)
    if (-not $Uri.IsAbsoluteUri) { Write-PMUError 'PMU.InvalidRequest' 'Repository endpoints must be absolute.' }
    if ("$($Uri.UserInfo)$($Uri.Query)$($Uri.Fragment)") {
        Write-PMUError 'PMU.InvalidRequest' 'Repository endpoints must be absolute and must not contain credentials, queries, or fragments.'
    }
    $Uri.AbsoluteUri.TrimEnd('/')
}
