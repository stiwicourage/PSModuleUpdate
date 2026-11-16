function Write-InstallationPhase {
    param(
        [object]$Plan,
        [string]$Phase
    )

    $hostState = Get-InstallationProgressHost
    if ($hostState.OutputRedirected -or $hostState.NonInteractive) {
        return
    }
    Write-InstallationProgress $Plan $Phase
}
