function Get-ModuleReferenceIdentity {
    param([System.Management.Automation.PSModuleInfo]$Module)
    if ($Module.Name -notmatch '^[A-Za-z0-9][A-Za-z0-9_.-]*$') { Write-PMUError 'PMU.InvalidRequest' 'A literal module identity is required.' }
    $identity = Get-ManifestIdentity (Join-Path $Module.ModuleBase "$($Module.Name).psd1")
    if ($identity.Guid -ne $Module.Guid -or [version]$identity.Version.NumericVersion -ne $Module.Version) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The supplied module reference differs from its manifest.'
    }
    $identity.Version = Get-ActiveModuleVersion $Module
    $identity
}
