function Get-PlanningInstallationSnapshot {
    param([object]$State)

    $installed = Select-NewestInstallation $State.Selected
    $treePath = Split-Path -Parent $installed.ManifestPath
    if ($State.FromBackup -and $installed.NumericVersion -eq $State.Journal.TargetNumericVersion) {
        $treePath = $State.Journal.BackupPath
    }
    $recovery = $null
    if ($State.FromBackup) {
        $recovery = $State.Journal
    }
    [pscustomobject]@{
        Installed = $installed
        InstalledTree = @(Get-FileTreeInventory $treePath)
        RecoveryJournal = $recovery
    }
}
