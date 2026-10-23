function Test-InstalledPlanState {
    param([object]$Operation)
    $plan = $Operation.Plan
    $current = @(Get-InstalledModuleIdentityList $plan.ModuleName $plan.Scope)
    Assert-SelectedInstallation $current $plan.ModuleGuid
    $target = @($current | Where-Object FullVersion -CEQ $plan.TargetVersion)
    if ($target.Count -eq 1) { return $true }
    $original = @($plan.ObservedInstalledVersions | Where-Object Scope -EQ $plan.Scope)
    if ((ConvertTo-Json @($current) -Depth 5 -Compress) -cne (ConvertTo-Json @($original) -Depth 5 -Compress)) {
        Write-PMUError 'PMU.InstalledStateChanged' 'The selected-scope installation changed after planning.'
    }
    Assert-FileTreeEqual $Operation.Record.InstalledTree @(Get-FileTreeInventory (Split-Path -Parent $plan.InstalledManifestPath)) 'PMU.InstalledStateChanged'
    $false
}
