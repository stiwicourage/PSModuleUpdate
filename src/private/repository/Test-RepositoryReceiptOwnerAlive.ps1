function Test-RepositoryReceiptOwnerAlive {
    param([object]$Receipt)
    if ([long]$Receipt.OwnerPid -gt [int]::MaxValue) {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt process identity is invalid.'
    }
    if ($IsLinux -and "$($Receipt.OwnerStartedUtcTicks)" -notmatch '^1[0-9]{17}$') {
        Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Legacy Linux repository receipt identity requires explicit recovery; automatic cleanup is disabled.'
    }
    $started = Get-RepositoryProcessStart ([int]$Receipt.OwnerPid)
    $started -ceq $Receipt.OwnerStartedUtcTicks
}
