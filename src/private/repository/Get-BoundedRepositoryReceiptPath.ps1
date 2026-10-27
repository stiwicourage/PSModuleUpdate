function Get-BoundedRepositoryReceiptPath {
    param(
        [string]$Path,
        [string]$Root
    )

    $safe = Assert-SafePath $Path
    if ([IO.Path]::GetDirectoryName($safe) -cne (Assert-SafePath $Root)) {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt path is invalid.'
    }
    if ((Get-Item -LiteralPath $safe).Length -gt 8192) {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt is oversized.'
    }
    $safe
}
