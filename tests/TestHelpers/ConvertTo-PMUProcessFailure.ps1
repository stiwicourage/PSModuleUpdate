function ConvertTo-PMUProcessFailure {
    param(
        [Management.Automation.ErrorRecord]$Failure,
        [string]$Mode
    )

    if ($Mode -eq 'Attempt' -and $Failure.FullyQualifiedErrorId -like 'PMU.LockTimeout*') {
        [pscustomobject]@{ ErrorId = $Failure.FullyQualifiedErrorId } | ConvertTo-Json -Compress
        exit 2
    }
    if ($Mode -notin @('Recover', 'RecoverBackup') -or $Failure.FullyQualifiedErrorId -notlike 'PMU.PlanStale*') {
        throw $Failure
    }
    [pscustomobject]@{
        Outcome = 'Recovered'
        ErrorId = $Failure.FullyQualifiedErrorId
    } | ConvertTo-Json -Compress
}
