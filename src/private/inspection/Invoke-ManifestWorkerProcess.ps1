function Invoke-ManifestWorkerProcess {
    param(
        [object]$Operation,
        [object]$Context
    )
    $worker = Invoke-NativeWorkerStart $Operation $Context
    try {
        $result = Read-NativeWorkerMessage $worker.Process.StandardOutput
    } finally {
        Wait-NativeWorkerStop $worker
        $worker.Process.Dispose()
    }
    Assert-ManifestWorkerResult $result $worker.ExitCode
}
