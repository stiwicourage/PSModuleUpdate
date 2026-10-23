function Get-PlanningInstallationState {
    param([string]$Name, [string]$Scope, [guid]$Guid)
    $state = Get-RecoveryAwareInstallation $Name $Scope $Guid
    $otherScope = 'AllUsers'
    if ($Scope -eq 'AllUsers') { $otherScope = 'CurrentUser' }
    $observed = @($state.Selected; Get-InstalledModuleIdentityList $Name $otherScope)
    $installed = Select-NewestInstallation $state.Selected
    $treePath = Split-Path -Parent $installed.ManifestPath
    if ($state.FromBackup -and $installed.NumericVersion -eq $state.Journal.TargetNumericVersion) { $treePath = $state.Journal.BackupPath }
    $recovery = $null
    if ($state.FromBackup) { $recovery = $state.Journal }
    [pscustomobject]@{ Observed = $observed; Installed = $installed; InstalledTree = @(Get-FileTreeInventory $treePath); RecoveryJournal = $recovery }
}
