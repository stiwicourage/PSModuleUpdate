function Initialize-ManifestInspection {
    param(
        [object]$Plan,
        [pscredential]$Credential,
        [bool]$AcceptLicense,
        [bool]$TrustRepository
    )
    $operation = Initialize-InstallationRequest $Plan $Credential @{
        AcceptLicense = $AcceptLicense
        TrustRepository = $TrustRepository
    }
    Assert-InstallationConsent $operation
    ConvertTo-ManifestInspectionOperation $operation
}
