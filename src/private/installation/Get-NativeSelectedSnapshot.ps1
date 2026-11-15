function Get-NativeSelectedSnapshot {
    param(
        [object]$Operation,
        [bool]$AlreadyInstalled
    )

    $path = Get-NativeSnapshotPath $Operation $AlreadyInstalled
    $source = Get-NativeSelectedSource $Operation $path (-not $AlreadyInstalled)
    [pscustomobject]@{
        Path = $path
        Source = $source
        Version = (Get-ManifestIdentity (Join-Path $path "$($Operation.Plan.ModuleName).psd1")).Version.FullVersion
        Tree = @(Get-FileTreeInventory $path)
    }
}
