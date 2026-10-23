function Get-InstalledModuleIdentityList {
    param([string]$Name, [string]$Scope, [string]$ExcludedPath)
    $root = Resolve-ModuleInstallationRoot $Scope
    $directory = Assert-SafePath (Join-Path $root $Name)
    if (-not (Test-Path -LiteralPath $directory)) { return }
    foreach ($child in Get-ChildItem -LiteralPath $directory -Directory -Force) {
        if ($child.FullName -ceq $ExcludedPath) { continue }
        $identity = Get-ManifestIdentity (Join-Path $child.FullName "$Name.psd1")
        if ($child.Name -cne $identity.Version.NumericVersion) {
            Write-PMUError 'PMU.UnsupportedInstallation' 'Only provider numeric-version directory layouts are supported.'
        }
        [pscustomobject]@{ FullVersion = $identity.Version.FullVersion; NumericVersion = $identity.Version.NumericVersion; Prerelease = $identity.Version.Prerelease; Scope = $Scope; Root = $root; ManifestPath = $identity.ManifestPath; Guid = $identity.Guid }
    }
}
