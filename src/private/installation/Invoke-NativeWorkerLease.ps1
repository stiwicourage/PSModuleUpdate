function Invoke-NativeWorkerLease {
    param([object]$Context)
    $operation = $Context.Operation
    $lease = Enter-InstallationLock $operation.LockPath
    try {
        Assert-NativeWorkerParent $Context
        $operation.Journal = Assert-NativeHandoffJournal $operation $Context.Token
        Assert-NativeSelectedInstallation $Context
        Write-NativeWorkerMessage (Invoke-OwnedNativeUpdate $Context)
    } finally {
        $lease.Dispose()
    }
}
