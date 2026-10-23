function Invoke-RecoveryRestoration {
    param([object]$Journal, [object]$Operation)
    try {
        if ($Journal.State -in @('Preparation', 'BackupReady')) {
            Write-RecoveryJournalState $Journal 'RecoveryCompleted'
        } else { Restore-InstallationBackup $Journal $Operation }
    } catch { Write-PMUError 'PMU.RecoveryFailed' 'Recovery could not be verified. The journal and surviving backup were preserved.' }
}
