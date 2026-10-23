function Initialize-StagedPackage {
    param([object]$Operation)
    Write-InstallationPhase $Operation.Plan 'Staging'
    Clear-StagingRoot $Operation
    Initialize-ControlledDirectory $Operation.StageRoot
    Assert-RepositoryBinding $Operation.Plan $Operation.RepositoryName
    Save-ProviderResource $Operation
    $manifest = Join-Path $Operation.StagedPath "$($Operation.Plan.ModuleName).psd1"
    Assert-PackageIdentity (Get-ManifestIdentity $manifest) $Operation.Plan
    $tree = @(Get-FileTreeInventory $Operation.StagedPath)
    if ($tree.Count -lt 2) { Write-PMUError 'PMU.VerificationFailed' 'The extracted module tree is incomplete.' }
    Assert-PackageSource $Operation.StagedPath $Operation.Plan
    $tree
}
