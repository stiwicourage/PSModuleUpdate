function Assert-NativeWorkerParent {
    param([object]$Context)
    $started = Get-RepositoryProcessStart $Context.ParentPid
    if (-not $started -or $started -cne $Context.ParentStarted) {
        Write-PMUError 'PMU.PlanStale' 'The approving parent process instance no longer exists.'
    }
}
