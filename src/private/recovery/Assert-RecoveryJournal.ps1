function Assert-RecoveryJournal {
    param(
        [object]$Journal,
        [object]$Operation
    )

    Assert-RecoveryJournalSchema $Journal
    $plan = $Operation.Plan
    $version = ConvertTo-CompleteModuleVersion $Journal.TargetVersion
    $expected = Get-ExpectedRecoveryJournalIdentity $plan $version
    Assert-MatchingProperty $Journal $expected @('SchemaVersion', 'ModuleName', 'ModuleGuid', 'Scope', 'DestinationRoot', 'TargetNumericVersion') 'PMU.RecoveryRequired'
    Assert-RecoveryPath $Journal $Operation
    if ($Journal.State -notin @('Preparation', 'BackupReady', 'ReplacementInProgress', 'Verification', 'Completed', 'RecoveryRequired', 'RecoveryCompleted')) {
        Write-PMUError 'PMU.RecoveryRequired' 'Recovery journal state is invalid.'
    }
}
