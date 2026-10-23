function Assert-ActivePlanIdentity {
    param([object]$Operation)
    $module = $Operation.Record.Module
    $path = Assert-SafePath (Join-Path $module.ModuleBase "$($module.Name).psd1")
    if ($path -cne $Operation.Record.ReferencePath -or $module.Guid -ne $Operation.Plan.ModuleGuid) {
        Write-PMUError 'PMU.PlanStale' 'The original active module identity or path changed.'
    }
    Assert-LoadedPlanIdentity $Operation
}
