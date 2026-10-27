function Write-RecoveryJournalState {
    param(
        [object]$Journal,
        [string]$State
    )

    $transitions = @{
        Preparation = @('Preparation', 'BackupReady', 'ReplacementInProgress', 'RecoveryCompleted')
        BackupReady = @('BackupReady', 'ReplacementInProgress', 'RecoveryCompleted')
        ReplacementInProgress = @('ReplacementInProgress', 'Verification', 'RecoveryRequired', 'RecoveryCompleted', 'Completed')
        Verification = @('Verification', 'Completed', 'RecoveryRequired', 'RecoveryCompleted')
        RecoveryRequired = @('RecoveryRequired', 'RecoveryCompleted', 'Completed')
        Completed = @('Completed')
        RecoveryCompleted = @('RecoveryCompleted')
    }
    if ($State -notin $transitions[$Journal.State]) {
        Write-PMUError 'PMU.RecoveryRequired' 'Invalid recovery journal state transition.'
    }
    $Journal.State = $State
    Write-DurableJournal $Journal
}
