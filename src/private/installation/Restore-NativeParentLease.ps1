function Restore-NativeParentLease {
    param([object]$Operation)
    if ($Operation.Lock -and $Operation.Lock.CanRead) {
        Assert-NativeParentLease $Operation
        return
    }
    $Operation.Lock = $null
    $Operation.Lock = Enter-InstallationLock $Operation.LockPath
}
