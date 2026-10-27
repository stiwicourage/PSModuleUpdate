function Get-RecoveryAwareInstallation {
    param(
        [string]$Name,
        [string]$Scope,
        [guid]$Guid
    )

    $journal = Get-PlanningRecoveryJournal $Name $Scope $Guid
    $selected = @(Get-RecoveryInstallationObservation $journal)
    $fromBackup = $selected.Count -gt 0
    if ($fromBackup) {
        $selected += @(Get-InstalledModuleIdentityList $Name $Scope $journal.TargetPath)
    } else {
        $selected = @(Get-InstalledModuleIdentityList $Name $Scope)
    }
    Assert-SelectedInstallation $selected $Guid
    [pscustomobject]@{
        Selected = $selected
        Journal = $journal
        FromBackup = $fromBackup
    }
}
