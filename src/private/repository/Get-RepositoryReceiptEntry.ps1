function Get-RepositoryReceiptEntry {
    param([string]$Root)
    $null = Assert-SafePath $Root
    if (-not (Test-Path -LiteralPath $Root)) { return }
    Initialize-ControlledDirectory $Root
    foreach ($file in Get-ChildItem -LiteralPath $Root -Filter '*.json' -File) {
        [pscustomobject]@{ Path = $file.FullName; Receipt = Read-RepositoryReceipt $file.FullName $Root }
    }
}
