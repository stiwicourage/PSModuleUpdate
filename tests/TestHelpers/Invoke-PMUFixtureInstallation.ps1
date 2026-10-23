function Invoke-PMUFixtureInstallation {
    param([object]$Operation)
    if (Test-Path -LiteralPath $Operation.Plan.TargetInstalledPath) {
        Remove-Item -LiteralPath $Operation.Plan.TargetInstalledPath -Recurse -Force
    }
    Copy-Item -LiteralPath $Operation.StagedPath -Destination (Split-Path -Parent $Operation.Plan.TargetInstalledPath) -Recurse
}
