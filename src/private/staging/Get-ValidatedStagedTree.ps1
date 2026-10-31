function Get-ValidatedStagedTree {
    param([object]$Operation)
    $manifest = Join-Path $Operation.StagedPath "$($Operation.Plan.ModuleName).psd1"
    Assert-PackageIdentity (Get-ManifestIdentity $manifest) $Operation.Plan
    Assert-InspectedManifest $Operation.Record (Get-FileHash -LiteralPath $manifest -Algorithm SHA256 -ErrorAction Stop).Hash
    $tree = @(Get-FileTreeInventory $Operation.StagedPath)
    if ($tree.Count -lt 2) {
        Write-PMUError 'PMU.VerificationFailed' 'The extracted module tree is incomplete.'
    }
    Assert-PackageSource $Operation.StagedPath $Operation.Plan
    $tree
}
