function Invoke-NativeWorkerExchange {
    param(
        [object]$Operation,
        [object]$Worker
    )

    $message = Read-NativeWorkerMessage $Worker.Process.StandardOutput
    if ($message.Phase -eq 'RESULT') {
        return $message
    }
    if ($message.Phase -cne 'READY') {
        Write-PMUError 'PMU.PlanStale' 'The native worker did not enter its nonmutating ready phase.'
    }
    Send-NativeWorkerGo $Operation $Worker
    Read-NativeWorkerMessage $Worker.Process.StandardOutput
}
