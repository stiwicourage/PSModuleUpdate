function Get-RecoveryInstallationObservation {
    param([object]$Journal)
    if (-not $Journal) { return }
    if ($Journal.State -in @('Completed', 'RecoveryCompleted', 'Preparation')) { return }
    if (-not $Journal.Reinstall) { return }
    $backup = Get-VerifiedRecoveryBackup $Journal 'PMU.RecoveryRequired'
    [pscustomobject]@{
        FullVersion = $backup.Version.FullVersion; NumericVersion = $backup.Version.NumericVersion; Prerelease = $backup.Version.Prerelease
        Scope = $Journal.Scope; Root = $Journal.DestinationRoot
        ManifestPath = Join-Path $Journal.TargetPath "$($Journal.ModuleName).psd1"; Guid = $backup.Guid
    }
}
