function ConvertTo-UpdateResult {
    param(
        [object]$Plan,
        [string]$Outcome,
        [string]$VerificationStatus = 'NotPerformed'
    )

    $installed = Get-ResultInstallationState $Plan $VerificationStatus
    $result = [pscustomobject]@{
        PSTypeName = 'PSModuleUpdate.UpdateResult'
        SchemaVersion = 1
        Outcome = $Outcome
    }
    $result | Add-Member -NotePropertyMembers (ConvertTo-UpdateResultIdentity $Plan)
    $result | Add-Member -NotePropertyMembers (ConvertTo-UpdateResultOutcome $Plan $installed $Outcome $VerificationStatus)
    $result
}
