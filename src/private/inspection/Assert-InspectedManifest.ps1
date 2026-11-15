function Assert-InspectedManifest {
    param(
        [object]$Record,
        [string]$Hash
    )
    $binding = $Record.PSObject.Properties['InspectedManifestHash']
    if ($binding -and $binding.Value -cne $Hash) {
        Write-PMUError 'PMU.TargetManifestChanged' 'The exact target manifest differs from the inspected manifest.' 'Obtain a fresh plan and inspect it again before approving installation.'
    }
}
