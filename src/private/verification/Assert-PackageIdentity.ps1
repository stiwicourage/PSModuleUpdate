function Assert-PackageIdentity {
    param([object]$Identity, [object]$Plan)
    if ($Identity.Name -cne $Plan.ModuleName -or $Identity.Version.FullVersion -cne $Plan.TargetVersion) {
        Write-PMUError 'PMU.VerificationFailed' 'The package manifest does not match the exact planned name and complete version.'
    }
    if ($Identity.Guid -ne $Plan.ModuleGuid) { Write-PMUError 'PMU.GuidMismatch' 'The package manifest GUID differs from the planned identity.' }
}
