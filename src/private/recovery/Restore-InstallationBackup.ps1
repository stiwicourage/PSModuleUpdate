function Restore-InstallationBackup {
    param(
        [object]$Journal,
        [object]$Operation
    )

    Assert-RecoveryJournal $Journal $Operation
    if ($Journal.Reinstall) {
        $null = Get-VerifiedRecoveryBackup $Journal
    }
    Clear-ControlledTarget $Journal
    if ($Journal.Reinstall) {
        Copy-Item -LiteralPath $Journal.BackupPath -Destination $Journal.TargetPath -Recurse -ErrorAction Stop
        Assert-FileTreeEqual @($Journal.BackupTree) @(Get-FileTreeInventory $Journal.TargetPath) 'PMU.RecoveryFailed'
    }
    $Journal.RecoveryStatus = 'Restored'
    Write-RecoveryJournalState $Journal 'RecoveryCompleted'
}
