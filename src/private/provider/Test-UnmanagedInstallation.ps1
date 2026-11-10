function Test-UnmanagedInstallation {
    param([object]$Operation, [string]$SelectedPath)
    if (-not $Operation.Consent['ReplaceUnmanagedInstallation']) {
        return $false
    }
    if ($SelectedPath -cne (Split-Path -Parent $Operation.Plan.InstalledManifestPath)) {
        return $false
    }
    -not (Test-Path -LiteralPath (Join-Path $SelectedPath 'PSGetModuleInfo.xml'))
}
