function ConvertTo-NativeWorkerResult {
    param(
        [object]$Operation,
        [System.Management.Automation.ErrorRecord]$Failure
    )

    $id = 'PMU.InstallationFailed'
    if ($Failure -and $Failure.FullyQualifiedErrorId -match '^PMU\.[A-Za-z]+') {
        $id = $Matches[0]
    }
    $token = $null
    if ($Operation) {
        $token = Get-NativeJournalToken $Operation
    }
    [pscustomobject]@{
        Phase = 'RESULT'
        Success = -not [bool]$Failure
        Token = $token
        ErrorId = $id
    }
}
