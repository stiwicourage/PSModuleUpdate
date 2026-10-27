function Select-NewestInstallation {
    param([object[]]$Installations)
    $newest = $null
    foreach ($installation in $Installations) {
        if (-not $newest) {
            $newest = $installation
            continue
        }
        if ((Compare-CompleteModuleVersion $installation.FullVersion $newest.FullVersion) -gt 0) {
            $newest = $installation
        }
    }
    $newest
}
