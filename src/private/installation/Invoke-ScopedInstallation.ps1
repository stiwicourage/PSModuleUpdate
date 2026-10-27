function Invoke-ScopedInstallation {
    param([object]$Operation)
    Initialize-ControlledDirectory $Operation.DataRoot
    Initialize-ControlledDirectory $Operation.WorkRoot
    $Operation.Lock = Enter-InstallationLock $Operation.LockPath
    try {
        Invoke-LockedInstallation $Operation
    } finally {
        if ($Operation.Lock) {
            $Operation.Lock.Dispose()
            $Operation.Lock = $null
        }
    }
}
