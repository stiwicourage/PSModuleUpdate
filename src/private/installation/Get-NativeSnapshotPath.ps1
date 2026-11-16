function Get-NativeSnapshotPath {
    param([object]$Operation, [bool]$AlreadyInstalled)
    if ($AlreadyInstalled) {
        return $Operation.Plan.TargetInstalledPath
    }
    Split-Path -Parent $Operation.Plan.InstalledManifestPath
}
