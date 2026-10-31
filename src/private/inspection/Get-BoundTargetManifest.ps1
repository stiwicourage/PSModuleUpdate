function Get-BoundTargetManifest {
    param([object]$Operation)
    Assert-ExactTarget $Operation
    Assert-InstallationConsent $Operation
    Invoke-ManifestAcquisition $Operation
    Get-InspectedTargetManifest $Operation
}
