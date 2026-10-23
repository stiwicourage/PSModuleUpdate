function Get-VerifiedRecoveryBackup {
    param([object]$Journal, [string]$ErrorId = 'PMU.RecoveryFailed')
    $manifest = Join-Path $Journal.BackupPath "$($Journal.ModuleName).psd1"
    $identity = Get-ManifestIdentity $manifest
    if ($identity.Guid -ne [guid]$Journal.ModuleGuid -or $identity.Version.FullVersion -cne $Journal.PreviousVersion) {
        Write-PMUError $ErrorId 'The surviving backup does not match the previous identity.'
    }
    Assert-FileTreeEqual @($Journal.BackupTree) @(Get-FileTreeInventory $Journal.BackupPath) $ErrorId
    $identity
}
