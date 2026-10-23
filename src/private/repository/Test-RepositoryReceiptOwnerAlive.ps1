function Test-RepositoryReceiptOwnerAlive {
    param([object]$Receipt)
    if ([long]$Receipt.OwnerPid -gt [int]::MaxValue) { Write-PMUError 'PMU.RepositoryRecoveryRequired' 'Repository receipt process identity is invalid.' }
    $started = Get-RepositoryProcessStart ([int]$Receipt.OwnerPid)
    $started -ceq $Receipt.OwnerStartedUtcTicks
}
