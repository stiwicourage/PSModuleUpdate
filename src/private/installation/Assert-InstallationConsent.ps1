function Assert-InstallationConsent {
    param([object]$Operation)
    Assert-RequiredConsent $Operation.Record.RequiresCredential ([bool]$Operation.Credential) 'PMU.AuthenticationFailed' 'Supply the direct credential again; PMU does not retain credentials between calls.'
    Assert-RequiredConsent $Operation.Plan.RequiresRepositoryTrust $Operation.Consent.TrustRepository 'PMU.RepositoryTrustRequired' 'Explicit -TrustRepository is required for this operation.'
    Assert-RequiredConsent ($Operation.Plan.RequiresLicenseAcceptance -or $Operation.RequiresLicenseAcceptance) $Operation.Consent.AcceptLicense 'PMU.LicenseAcceptanceRequired' 'Explicit -AcceptLicense is required when package license requirements are declared or undisclosed.'
}
