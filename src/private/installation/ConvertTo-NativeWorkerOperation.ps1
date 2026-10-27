function ConvertTo-NativeWorkerOperation {
    param(
        [object]$Operation,
        [object]$Snapshot
    )

    $fields = 'Plan Consent Credential DataRoot WorkRoot LockPath JournalPath StageRoot BackupPath StagedPath Reinstall Journal RecoveryStatus RequiresLicenseAcceptance'.Split(' ')
    $copy = $Operation | Select-Object -Property $fields
    $copy | Add-Member RepositoryName $Snapshot.Source.Name
    $copy | Add-Member Record ([pscustomobject]@{ InstalledTree = @($Operation.Record.InstalledTree) })
    $copy | Add-Member NativeContext ([pscustomobject]@{
            Root = Get-NativeProviderRoot $Operation
            Paths = $null
            CurrentUserRoot = Resolve-ModuleInstallationRoot 'CurrentUser'
        })
    $copy
}
