function Complete-NativeWorkerLease {
    param(
        [object]$Operation,
        [object]$Worker
    )

    try {
        Wait-NativeWorkerStop $Worker
    } finally {
        try {
            Restore-NativeParentLease $Operation
        } finally {
            $Worker.Process.Dispose()
        }
    }
}
