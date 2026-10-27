function Invoke-LockedInstallation {
    param([object]$Operation)
    Assert-PlanEnvironment $Operation
    Repair-UnfinishedInstallation $Operation
    $alreadyInstalled = Test-InstalledPlanState $Operation
    Clear-CompletedOperation $Operation
    Assert-ExactTarget $Operation
    Assert-InstallationConsent $Operation
    $tree = @(Invoke-NativeHandoff $Operation $alreadyInstalled)
    Complete-VerifiedInstallation $Operation $tree $alreadyInstalled
}
