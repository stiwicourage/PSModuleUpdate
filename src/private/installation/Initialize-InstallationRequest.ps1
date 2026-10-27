function Initialize-InstallationRequest {
    param(
        [object]$Update,
        [pscredential]$Credential,
        [hashtable]$Consent
    )

    $record = Test-UpdatePlan $Update
    $operation = ConvertTo-InstallationOperation $Update $record $Consent $Credential
    Assert-PlanEnvironment $operation
    if ($Update.RepositoryName) {
        Assert-ExactTarget $operation
    }
    $journal = Read-RecoveryJournal $operation
    if (-not $journal -or $journal.State -in @('Completed', 'RecoveryCompleted')) {
        $null = Test-InstalledPlanState $operation
    }
    $operation
}
