function Complete-RecoveryTarget {
    param([object]$Journal, [object]$Operation)
    if (-not (Test-RecoveryTargetComplete $Journal)) { return $false }
    $Journal.RecoveryStatus = 'TargetVerified'
    Write-RecoveryJournalState $Journal 'Completed'
    $Operation.RecoveryStatus = 'TargetVerified'
    $true
}
