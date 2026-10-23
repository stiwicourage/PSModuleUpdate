function Assert-RecoveryTargetVersion {
    param([hashtable]$Manifest, [object]$Journal)
    if (-not $Manifest['ModuleVersion']) { return }
    $version = Get-ManifestModuleVersion $Manifest
    if ($version.FullVersion -cnotin @($Journal.PreviousVersion, $Journal.TargetVersion)) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'Recovery refuses to remove an unrelated full-version identity from the numeric target.'
    }
}
