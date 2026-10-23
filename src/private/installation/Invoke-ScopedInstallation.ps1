function Invoke-ScopedInstallation {
    param([object]$Operation)
    Initialize-ControlledDirectory $Operation.DataRoot
    Initialize-ControlledDirectory $Operation.WorkRoot
    $lock = Enter-InstallationLock $Operation.LockPath
    try { Invoke-LockedInstallation $Operation }
    finally { $lock.Dispose() }
}
