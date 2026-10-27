function Write-InstallationPhase {
    param(
        [object]$Plan,
        [string]$Phase
    )

    if ([Console]::IsOutputRedirected) {
        return
    }
    if ([Environment]::GetCommandLineArgs() -contains '-NonInteractive') {
        return
    }
    $progressId = 17330 # Stable native progress activity for the single-module workflow.
    $activity = "Updating $($Plan.ModuleName)"
    if ($Phase -eq 'Completed') {
        Write-Progress -Id $progressId -Activity $activity -Completed
        return
    }
    Write-Progress -Id $progressId -Activity $activity -Status $Phase
}
