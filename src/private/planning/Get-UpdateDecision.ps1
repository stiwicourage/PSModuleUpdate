function Get-UpdateDecision {
    param([object]$Context)
    $target = $Context.Target.Version.FullVersion
    $advancesActive = Test-TargetAdvancesActiveVersion $target $Context.Active
    $installedComparison = Compare-CompleteModuleVersion $target $Context.Installed.FullVersion
    if (-not $advancesActive) {
        return ConvertTo-UpdateDecision 'UpToDate'
    }
    if ($installedComparison -gt 0) {
        return ConvertTo-UpdateDecision 'UpdateAvailable'
    }
    if ($Context.Active) {
        return ConvertTo-UpdateDecision 'AlreadyInstalledRestartRequired'
    }
    ConvertTo-UpdateDecision 'UpToDate'
}
