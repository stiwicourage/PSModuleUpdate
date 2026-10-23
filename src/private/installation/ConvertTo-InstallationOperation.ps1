function ConvertTo-InstallationOperation {
    param([object]$Plan, [object]$Record, [hashtable]$Consent, [pscredential]$Credential)
    $dataRoot = Resolve-PMUDataRoot $Plan.Scope
    $work = Join-Path $dataRoot (Get-InstallationLockIdentity $Plan)
    [pscustomobject]@{
        Plan = $Plan; Record = $Record; Consent = $Consent; Credential = $Credential
        RepositoryName = $null
        DataRoot = $dataRoot; WorkRoot = $work; LockPath = Join-Path $work 'operation.lock'
        JournalPath = Join-Path $work 'journal.json'; StageRoot = Join-Path $work 'stage'
        BackupPath = Join-Path $work 'backup'; Reinstall = $false; Journal = $null
        StagedPath = Join-Path $work "stage/$($Plan.ModuleName)/$($Plan.TargetNumericVersion)"
        RecoveryStatus = 'NotRequired'
        RequiresLicenseAcceptance = $false
    }
}
