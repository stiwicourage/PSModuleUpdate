function Get-RepositoryProcessStart {
    param([int]$ProcessId)
    try {
        $process = [Diagnostics.Process]::GetProcessById($ProcessId)
    } catch [ArgumentException] {
        return $null
    }
    try {
        "$($process.StartTime.ToUniversalTime().Ticks)"
    } catch {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Cannot verify the repository receipt owner process.'
    } finally {
        $process.Dispose()
    }
}
