function Invoke-NativeWorker {
    param([object]$Context)
    try {
        Initialize-NativeProvider $Context.Operation
        Invoke-NativeWorkerAction $Context
    } catch {
        Write-NativeWorkerMessage (ConvertTo-NativeWorkerResult $null $_)
    }
}
