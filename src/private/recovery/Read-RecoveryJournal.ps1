function Read-RecoveryJournal {
    param([object]$Operation)
    if (-not (Test-Path -LiteralPath $Operation.JournalPath)) {
        return $null
    }
    try {
        $null = Assert-SafePath $Operation.JournalPath
        $journal = Get-Content -LiteralPath $Operation.JournalPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        Assert-RecoveryJournal $journal $Operation
        return $journal
    } catch {
        Write-PMUError 'PMU.RecoveryRequired' 'The journal or its paths are unsafe. Preserve PMU data for manual inspection.'
    }
}
