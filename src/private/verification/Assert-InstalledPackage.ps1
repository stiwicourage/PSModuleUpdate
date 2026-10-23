function Assert-InstalledPackage {
    param([object]$Operation, [object[]]$ReferenceTree)
    $plan = $Operation.Plan
    $path = Assert-SafePath $plan.TargetInstalledPath
    $expected = Join-Path (Resolve-ModuleInstallationRoot $plan.Scope) "$($plan.ModuleName)/$($plan.TargetNumericVersion)"
    if ($path -cne $expected) { Write-PMUError 'PMU.VerificationFailed' 'The provider destination does not match the planned scope root.' }
    $manifest = Join-Path $path "$($plan.ModuleName).psd1"
    Assert-PackageIdentity (Get-ManifestIdentity $manifest) $plan
    Assert-FileTreeEqual $ReferenceTree @(Get-FileTreeInventory $path)
    Assert-PackageSource $path $plan
    $discovered = @(Get-Module -ListAvailable $manifest | Where-Object Guid -EQ $plan.ModuleGuid)
    if ($discovered.Count -ne 1) { Write-PMUError 'PMU.VerificationFailed' 'The installed module is not discoverable at its exact manifest path.' }
}
