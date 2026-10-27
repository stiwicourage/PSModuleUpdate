function Invoke-NativeWorkerProcess {
    param(
        [object]$Operation,
        [object]$Context
    )

    $worker = Invoke-NativeWorkerStart $Operation $Context
    $response = $null
    try {
        $response = Invoke-NativeWorkerExchange $Operation $worker
    } finally {
        Complete-NativeWorkerLease $Operation $worker
    }
    if ($worker.ExitCode -ne 0) {
        Write-PMUError 'PMU.RecoveryRequired' 'The native worker exited unsuccessfully. Pending state was preserved.'
    }
    $response
}
