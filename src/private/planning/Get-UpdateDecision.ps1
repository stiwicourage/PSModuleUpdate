function Get-UpdateDecision {
    param([object]$Context)
    $target = $Context.Target.Version.FullVersion
    $advancesActive = Test-TargetAdvancesActiveVersion $target $Context.Active
    $installedComparison = Compare-CompleteModuleVersion $target $Context.Installed.FullVersion
    $unchanged = @{ Available = $false; Disposition = 'UpToDate'; Reason = 'No release newer than both actual active and installed versions is available.'; Restart = $false }
    if (-not $advancesActive) { return $unchanged }
    if ($installedComparison -gt 0) {
        return @{ Available = $true; Disposition = 'UpdateAvailable'; Reason = 'An exact newer release is available.'; Restart = $false }
    }
    if ($Context.Active) { return @{ Available = $false; Disposition = 'AlreadyInstalledRestartRequired'; Reason = 'A newer version is already installed in the selected scope.'; Restart = $true } }
    $unchanged
}
