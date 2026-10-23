function Get-RepositoryUriHash {
    param([uri]$Uri)
    $normalized = Assert-RepositoryUri $Uri
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($normalized)))
}
