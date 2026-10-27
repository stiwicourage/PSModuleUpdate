function Get-RepositoryProcessStart {
    param([int]$ProcessId)
    try {
        Get-PlatformRepositoryProcessStart $ProcessId
    } catch [ArgumentException] {
        return $null
    } catch {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Cannot verify the repository receipt owner process.'
    }
}
