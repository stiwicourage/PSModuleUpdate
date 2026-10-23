function Assert-LoadedPlanIdentity {
    param([object]$Operation)
    $active = Get-ActiveModuleIdentity $Operation.Record.Module
    $actual = @{ ActivePath = $null; ActiveVersion = $null }
    if ($active) { $actual = @{ ActivePath = $active.ManifestPath; ActiveVersion = $active.Version.FullVersion } }
    Assert-MatchingProperty $actual $Operation.Plan @('ActivePath', 'ActiveVersion') 'PMU.PlanStale'
}
