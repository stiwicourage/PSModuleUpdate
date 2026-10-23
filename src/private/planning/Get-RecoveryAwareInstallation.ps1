function Get-RecoveryAwareInstallation {
    param([string]$Name, [string]$Scope, [guid]$Guid)
    $root = Resolve-ModuleInstallationRoot $Scope
    $identity = [pscustomobject]@{ ModuleName = $Name; ModuleGuid = $Guid; Scope = $Scope; DestinationRoot = $root; TargetNumericVersion = '0.0.0' }
    $operation = ConvertTo-InstallationOperation $identity $null @{} $null
    $journal = Read-RecoveryJournal $operation
    $selected = @(Get-RecoveryInstallationObservation $journal)
    $fromBackup = $selected.Count -gt 0
    if ($fromBackup) { $selected += @(Get-InstalledModuleIdentityList $Name $Scope $journal.TargetPath) }
    else { $selected = @(Get-InstalledModuleIdentityList $Name $Scope) }
    Assert-SelectedInstallation $selected $Guid
    [pscustomobject]@{ Selected = $selected; Journal = $journal; FromBackup = $fromBackup }
}
