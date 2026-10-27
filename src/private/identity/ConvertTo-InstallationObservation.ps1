function ConvertTo-InstallationObservation {
    param(
        [object]$Identity,
        [object]$Scope,
        [object]$Root,
        [object]$ManifestPath
    )

    # Identity is a verified manifest identity with Version and Guid; expose only planning fields.
    [pscustomobject]@{
        FullVersion = $Identity.Version.FullVersion
        NumericVersion = $Identity.Version.NumericVersion
        Prerelease = $Identity.Version.Prerelease
        Scope = $Scope
        Root = $Root
        ManifestPath = $ManifestPath
        Guid = $Identity.Guid
    }
}
