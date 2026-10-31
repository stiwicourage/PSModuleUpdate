function Assert-ManifestWorkerResult {
    param(
        [object]$Result,
        [int]$ExitCode
    )
    $complete = $ExitCode -eq 0 -and $Result.Phase -ceq 'RESULT'
    if ($complete -and $Result.Success) {
        return
    }
    Write-ManifestWorkerError $Result
}
