function Assert-NativeInstallationSnapshot {
    param([object]$Context)

    $operation = $Context.Operation
    $expected = [pscustomobject]@{
        ModuleName = $operation.Plan.ModuleName
        ModuleGuid = $operation.Plan.ModuleGuid
        TargetVersion = $Context.Snapshot.Version
    }
    Assert-PackageIdentity (Get-ManifestIdentity (Join-Path $Context.Snapshot.Path "$($operation.Plan.ModuleName).psd1")) $expected
    Assert-FileTreeEqual @($Context.Snapshot.Tree) @(Get-FileTreeInventory $Context.Snapshot.Path) 'PMU.InstalledStateChanged'
    $source = Get-NativeInstalledSource $operation $Context.Snapshot.Path
    Assert-MatchingProperty $source $Context.Snapshot.Source @('Name', 'Uri') 'PMU.InstalledStateChanged'
}
