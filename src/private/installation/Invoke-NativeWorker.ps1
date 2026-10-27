function Invoke-NativeWorker {
    param([object]$Context)
    try {
        Initialize-NativeProvider $Context.Operation
        Write-NativeWorkerMessage ([pscustomobject]@{ Phase = 'READY' })
        Assert-NativeWorkerGo ([Console]::In)
        Invoke-NativeWorkerLease $Context
    } catch {
        Write-NativeWorkerMessage (ConvertTo-NativeWorkerResult $null $_)
    }
}
