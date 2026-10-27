function Get-ResultInstallationState {
    param(
        [object]$Plan,
        [string]$VerificationStatus
    )

    if ($VerificationStatus -ne 'Verified') {
        return @{
            Version = $Plan.InstalledVersion
            Path = Split-Path -Parent $Plan.InstalledManifestPath
        }
    }
    $identity = Get-ManifestIdentity (Join-Path $Plan.TargetInstalledPath "$($Plan.ModuleName).psd1")
    @{
        Version = $identity.Version.FullVersion
        Path = $Plan.TargetInstalledPath
    }
}
