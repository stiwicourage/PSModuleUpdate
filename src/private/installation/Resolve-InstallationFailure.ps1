function Resolve-InstallationFailure {
    param([object]$Operation, [System.Management.Automation.ErrorRecord]$Failure)
    try { Restore-InstallationBackup $Operation.Journal $Operation }
    catch {
        $Operation.Journal.RecoveryStatus = 'Failed'
        Write-RecoveryJournalState $Operation.Journal 'RecoveryRequired'
        Write-PMUError 'PMU.RollbackFailed' 'Installation and rollback both failed. Recoverable evidence was preserved.' 'Do not delete the PMU journal or backup; inspect the selected installation before obtaining a fresh plan.'
    }
    if ($Failure.FullyQualifiedErrorId -like 'PMU.*') { throw $Failure }
    Write-ProviderError $Failure 'PMU.InstallationFailed'
}
