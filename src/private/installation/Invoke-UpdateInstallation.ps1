function Invoke-UpdateInstallation {
    param([object]$Operation)
    Assert-InstallationConsent $Operation
    Write-InstallationPhase $Operation.Plan 'Checking'
    try { Invoke-RepositoryInstallation $Operation }
    catch [UnauthorizedAccessException] { Write-PMUError 'PMU.PermissionDenied' 'The selected scope is not writable. PMU does not elevate or change scope.' }
    finally { Write-InstallationPhase $Operation.Plan 'Completed' }
}
