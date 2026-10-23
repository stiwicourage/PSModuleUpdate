function Copy-InstallationBackup {
    param([object]$Operation)
    $journal = $Operation.Journal
    $null = Assert-SafePath $Operation.Plan.TargetInstalledPath
    $journal.BackupTree = @(Get-FileTreeInventory $Operation.Plan.TargetInstalledPath)
    Copy-Item -LiteralPath $Operation.Plan.TargetInstalledPath -Destination $Operation.BackupPath -Recurse -ErrorAction Stop
    Assert-FileTreeEqual $journal.BackupTree @(Get-FileTreeInventory $Operation.BackupPath)
    Write-RecoveryJournalState $journal 'BackupReady'
}
