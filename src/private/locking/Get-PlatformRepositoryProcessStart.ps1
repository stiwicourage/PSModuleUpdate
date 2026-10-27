function Get-PlatformRepositoryProcessStart {
    param([int]$ProcessId)
    if ($IsLinux) {
        return Get-LinuxRepositoryProcessStart $ProcessId
    }
    $process = [Diagnostics.Process]::GetProcessById($ProcessId)
    try {
        "$($process.StartTime.ToUniversalTime().Ticks)"
    } finally {
        $process.Dispose()
    }
}
