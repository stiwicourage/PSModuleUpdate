function Assert-PMULicenseConsent {
    param([object]$Plan)
    try { $null = $Plan | Install-PSModuleUpdate -TrustRepository -Confirm:$false }
    catch {
        if ($_.FullyQualifiedErrorId -notlike 'PMU.LicenseAcceptanceRequired*') { throw }
        return
    }
    throw 'A licensed fixture was installed without explicit acceptance.'
}
