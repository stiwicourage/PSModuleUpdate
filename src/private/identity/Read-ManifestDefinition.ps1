function Read-ManifestDefinition {
    param(
        [string]$ManifestPath
    )

    # The identity caller supplies the canonical path already checked by Assert-SafePath.
    try {
        $data = Import-PowerShellDataFile -LiteralPath $ManifestPath -ErrorAction Stop
    } catch {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The module manifest cannot be safely read.'
    }
    if (-not $data['GUID'] -or -not $data['ModuleVersion']) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The module manifest must declare version and GUID.'
    }
    Assert-ManifestRootModule $data $ManifestPath
    $data
}
