function Get-RecoveryInstallationObservation {
    param([object]$Journal)
    if (-not $Journal) {
        return
    }
    if ($Journal.State -in @('Completed', 'RecoveryCompleted', 'Preparation')) {
        return
    }
    if (-not $Journal.Reinstall) {
        return
    }
    $backup = Get-VerifiedRecoveryBackup $Journal 'PMU.RecoveryRequired'
    $manifestPath = Join-Path $Journal.TargetPath "$($Journal.ModuleName).psd1"
    ConvertTo-InstallationObservation $backup $Journal.Scope $Journal.DestinationRoot $manifestPath
}
