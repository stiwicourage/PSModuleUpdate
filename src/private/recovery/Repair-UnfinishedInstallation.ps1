function Repair-UnfinishedInstallation {
    param([object]$Operation)
    $journal = Read-RecoveryJournal $Operation
    if (-not $journal -or $journal.State -in @('Completed', 'RecoveryCompleted')) { return }
    Write-InstallationPhase $Operation.Plan 'Recovering'
    if (Complete-RecoveryTarget $journal $Operation) { return }
    Invoke-RecoveryRestoration $journal $Operation
    $null = (Get-LivePlanRegistry).Remove($Operation.Plan)
    Write-PMUError 'PMU.PlanStale' 'An unfinished operation was recovered. Obtain a fresh plan before another update.'
}
