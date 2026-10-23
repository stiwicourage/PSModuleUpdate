function Test-TargetAdvancesActiveVersion {
    param([string]$TargetVersion, [object]$Active)
    if (-not $Active) { return $true }
    (Compare-CompleteModuleVersion $TargetVersion $Active.Version.FullVersion) -gt 0
}
