function Assert-ObservedNativeIdentity {
    param(
        [object]$Operation,
        [string]$Manifest
    )

    $known = @($Operation.Plan.ObservedInstalledVersions | Where-Object ManifestPath -CEQ $Manifest)
    if ($known.Count -ne 1 -or $known[0].Scope -cne $Operation.Plan.Scope) {
        Write-PMUError 'PMU.UnsupportedInstallation' 'Native update selected an installation outside the approved scope observations.'
    }
    $expected = [pscustomobject]@{
        ModuleName = $Operation.Plan.ModuleName
        ModuleGuid = $Operation.Plan.ModuleGuid
        TargetVersion = $known[0].FullVersion
    }
    Assert-PackageIdentity (Get-ManifestIdentity $Manifest) $expected
}
