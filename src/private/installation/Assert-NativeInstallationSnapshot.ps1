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
    $source = Get-NativeSelectedSource $operation $Context.Snapshot.Path $Context.Snapshot.Source.Unmanaged
    Assert-MatchingProperty $source $Context.Snapshot.Source @('Name', 'Uri', 'Unmanaged') 'PMU.InstalledStateChanged'
}
