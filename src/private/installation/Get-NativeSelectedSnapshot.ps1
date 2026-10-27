function Get-NativeSelectedSnapshot {
    param(
        [object]$Operation,
        [bool]$AlreadyInstalled
    )

    $path = Split-Path -Parent $Operation.Plan.InstalledManifestPath
    if ($AlreadyInstalled) {
        $path = $Operation.Plan.TargetInstalledPath
    }
    $source = Get-NativeInstalledSource $Operation $path
    [pscustomobject]@{
        Path = $path
        Source = $source
        Version = (Get-ManifestIdentity (Join-Path $path "$($Operation.Plan.ModuleName).psd1")).Version.FullVersion
        Tree = @(Get-FileTreeInventory $path)
    }
}
