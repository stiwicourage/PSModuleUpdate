function Initialize-NativeWorkerStartInfo {
    param([object]$Context)

    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    $bootstrap = Get-NativeWorkerBootstrap

    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command', $bootstrap)) {
        $start.ArgumentList.Add($argument)
    }

    Initialize-NativeWorkerEnvironment $start $Context.Operation.NativeContext.Root
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start
}
