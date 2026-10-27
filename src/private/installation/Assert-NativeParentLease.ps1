function Assert-NativeParentLease {
    param([object]$Operation)
    if ($Operation.Lock -isnot [IO.FileStream]) {
        Write-PMUError 'PMU.PlanStale' 'The parent does not own the original installation lock.'
    }
    if (-not $Operation.Lock.CanRead -or $Operation.Lock.Name -cne $Operation.LockPath) {
        Write-PMUError 'PMU.PlanStale' 'The parent no longer owns its original lock file.'
    }
}
