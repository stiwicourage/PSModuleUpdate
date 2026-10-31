function ConvertTo-NativeWorkerOperation {
    param(
        [object]$Operation,
        [object]$Snapshot
    )

    $fields = 'Plan Consent Credential DataRoot WorkRoot LockPath JournalPath StageRoot BackupPath StagedPath Reinstall Journal RecoveryStatus RequiresLicenseAcceptance'.Split(' ')
    $copy = $Operation | Select-Object -Property $fields
    $copy | Add-Member RepositoryName $Snapshot.Source.Name
    $copy | Add-Member Record (ConvertTo-NativePlanRecord $Operation.Record)
    $copy | Add-Member NativeContext (ConvertTo-NativeProviderContext $Operation)
    $copy
}
