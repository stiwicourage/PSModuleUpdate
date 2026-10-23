function Clear-CompletedOperation {
    param([object]$Operation)
    $journal = Read-RecoveryJournal $Operation
    if (-not $journal) { return }
    if ($journal.State -notin @('Completed', 'RecoveryCompleted')) {
        Write-PMUError 'PMU.RecoveryRequired' 'Unfinished recovery evidence cannot be discarded.'
    }
    foreach ($path in @($Operation.StageRoot, $Operation.BackupPath)) {
        $null = Assert-SafePath $path
        if (Test-Path -LiteralPath $path) {
            $null = @(Get-FileTreeInventory $path)
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
        }
    }
}
