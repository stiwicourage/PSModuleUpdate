function ConvertTo-InstallationOperation {
    param(
        [object]$Plan,
        [object]$Record,
        [hashtable]$Consent,
        [pscredential]$Credential
    )

    $dataRoot = Resolve-PMUDataRoot $Plan.Scope
    $work = Join-Path $dataRoot (Get-InstallationLockIdentity $Plan)
    $operation = [pscustomobject]@{
        Plan = $Plan
        Record = $Record
        Consent = $Consent
        Credential = $Credential
        RepositoryName = $null
    }
    $operation | Add-Member -NotePropertyMembers (ConvertTo-InstallationWorkspace $Plan $dataRoot $work)
    $operation
}
