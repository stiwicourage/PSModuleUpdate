function Close-PMUChildProcess {
    param([Diagnostics.Process[]]$Process)
    foreach ($child in $Process) {
        if (-not $child.HasExited) { $child.Kill($true) }
        $child.Dispose()
    }
}
