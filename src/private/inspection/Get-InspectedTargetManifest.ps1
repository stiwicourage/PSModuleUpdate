function Get-InspectedTargetManifest {
    param([object]$Operation)
    Assert-PlanEnvironment $Operation
    $null = Test-InstalledPlanState $Operation
    $path = Join-Path $Operation.StagedPath "$($Operation.Plan.ModuleName).psd1"
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
    Assert-PackageIdentity (Get-ManifestIdentity $path) $Operation.Plan
    $manifest = Read-ManifestDefinition $path
    Assert-ManifestReadHash $path $hash
    Assert-InspectedManifest $Operation.Record $hash
    $Operation.Record | Add-Member InspectedManifestHash $hash -Force
    ConvertTo-TargetManifest $Operation.Plan $manifest
}
