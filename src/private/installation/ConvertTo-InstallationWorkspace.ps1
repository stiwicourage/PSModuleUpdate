function ConvertTo-InstallationWorkspace {
    param(
        [object]$Plan,
        [object]$DataRoot,
        [object]$WorkRoot
    )

    [ordered]@{
        DataRoot = $DataRoot
        WorkRoot = $WorkRoot
        LockPath = Join-Path $WorkRoot 'operation.lock'
        JournalPath = Join-Path $WorkRoot 'journal.json'
        StageRoot = Join-Path $WorkRoot 'stage'
        BackupPath = Join-Path $WorkRoot 'backup'
        Reinstall = $false
        Journal = $null
        Lock = $null
        StagedPath = Join-Path $WorkRoot "stage/$($Plan.ModuleName)/$($Plan.TargetNumericVersion)"
        RecoveryStatus = 'NotRequired'
        RequiresLicenseAcceptance = $false
    }
}
