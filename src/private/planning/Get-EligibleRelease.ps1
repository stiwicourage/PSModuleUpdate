function Get-EligibleRelease {
    param([object[]]$Releases, [string]$Channel)
    foreach ($release in $Releases) {
        if ($Channel -eq 'Stable' -and $release.Version.IsPrerelease) { continue }
        $release
    }
}
