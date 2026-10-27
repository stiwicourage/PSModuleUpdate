function Select-UpdateTarget {
    param(
        [object[]]$Releases,
        [string]$Channel
    )

    $target = $null
    foreach ($release in (Get-EligibleRelease $Releases $Channel)) {
        if (-not $target) {
            $target = $release
            continue
        }
        if ((Compare-CompleteModuleVersion $release.Version.FullVersion $target.Version.FullVersion) -gt 0) {
            $target = $release
        }
    }
    if (-not $target) {
        Write-PMUError 'PMU.PackageNotFound' 'No eligible package was found in the explicit repository.'
    }
    $target
}
