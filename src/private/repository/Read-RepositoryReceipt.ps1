function Read-RepositoryReceipt {
    param([string]$Path, [string]$Root)
    $safe = Assert-SafePath $Path
    if ([IO.Path]::GetDirectoryName($safe) -cne (Assert-SafePath $Root)) { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt path is invalid.' }
    if ((Get-Item -LiteralPath $safe).Length -gt 8192) { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt is oversized.' }
    try { $receipt = Get-Content -LiteralPath $safe -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
    catch { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt is unreadable or incomplete.' }
    Assert-RepositoryReceipt $receipt
    if ([IO.Path]::GetFileName($safe) -cne "$($receipt.OperationId).json") { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt name does not match its operation.' }
    $receipt
}
