function Enter-InstallationLock {
    param([string]$Path, [int]$TimeoutMilliseconds = 5000)
    $null = Assert-SafePath $Path
    $timer = [Diagnostics.Stopwatch]::StartNew()
    do {
        try { return [IO.File]::Open($Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
        catch [UnauthorizedAccessException] { Write-PMUError 'PMU.PermissionDenied' 'Cannot open the scope-specific PMU lock.' }
        catch [IO.IOException] { Start-Sleep -Milliseconds 50 }
    } while ($timer.ElapsedMilliseconds -lt $TimeoutMilliseconds)
    Write-PMUError 'PMU.LockTimeout' 'Another process holds the module/scope/root lock. Retry after it completes.'
}
