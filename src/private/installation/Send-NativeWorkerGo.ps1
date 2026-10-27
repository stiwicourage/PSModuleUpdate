function Send-NativeWorkerGo {
    param(
        [object]$Operation,
        [object]$Worker
    )

    Assert-NativeParentLease $Operation
    $Operation.Lock.Dispose()
    $Operation.Lock = $null
    $Worker.Process.StandardInput.WriteLine('GO')
    $Worker.Process.StandardInput.Close()
}
