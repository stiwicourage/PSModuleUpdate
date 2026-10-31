function Assert-ManifestReadHash {
    param(
        [string]$Path,
        [string]$Hash
    )
    $current = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($current -cne $Hash) {
        Write-PMUError 'PMU.TargetManifestChanged' 'The target manifest changed while being inspected.' 'Obtain a fresh plan and inspect it again.'
    }
}
