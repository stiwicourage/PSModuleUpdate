function Assert-ReferenceInstallationLayout {
    param([object]$Reference, [object[]]$Observed, [object]$RecoveryJournal)
    $installations = @($Observed | Where-Object ManifestPath -CEQ $Reference.ManifestPath)
    if ($installations.Count -eq 1) { return }
    Assert-BackupReferenceIdentity $Reference $RecoveryJournal
}
