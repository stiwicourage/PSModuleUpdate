function Assert-BackupReferenceIdentity {
    param([object]$Reference, [object]$Journal)
    if (-not $Journal) { Write-PMUError 'PMU.UnsupportedInstallation' 'The reference must identify an installed module or a validated unfinished-operation backup.' }
    $backup = Get-VerifiedRecoveryBackup $Journal 'PMU.RecoveryRequired'
    Assert-MatchingProperty $Reference $backup @('Name', 'Guid', 'ManifestPath') 'PMU.UnsupportedInstallation'
    if ($Reference.Version.FullVersion -cne $backup.Version.FullVersion) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The backup reference full version differs from the verified previous installation.'
    }
}
