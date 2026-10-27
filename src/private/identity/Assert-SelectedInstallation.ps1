function Assert-SelectedInstallation {
    param(
        [object[]]$Installations,
        [guid]$Guid
    )

    if (-not $Installations.Count) {
        Write-PMUError 'PMU.UnsupportedInstallation' 'No existing installation was found in the requested scope.'
    }
    if (@($Installations | Where-Object Guid -NE $Guid).Count) {
        Write-PMUError 'PMU.GuidMismatch' 'A selected-scope manifest has a different GUID.'
    }
}
