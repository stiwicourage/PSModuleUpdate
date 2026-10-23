function Wait-PMUFixtureSignal {
    param([string]$Root, [string]$Pattern, [int]$Count = 1)
    $deadline = [datetime]::UtcNow.AddSeconds(30)
    while (@(Get-ChildItem -LiteralPath $Root -Filter $Pattern).Count -lt $Count) {
        if ([datetime]::UtcNow -gt $deadline) { throw 'Fixture readiness timed out.' }
        Start-Sleep -Milliseconds 50
    }
}
