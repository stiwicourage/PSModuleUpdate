function ConvertTo-UpdateResult {
    param([object]$Plan, [string]$Outcome, [string]$VerificationStatus = 'NotPerformed')
    $installed = Get-ResultInstallationState $Plan $VerificationStatus
    [pscustomobject]@{
        PSTypeName = 'PSModuleUpdate.UpdateResult'; SchemaVersion = 1; Outcome = $Outcome
        ModuleName = $Plan.ModuleName; ModuleGuid = $Plan.ModuleGuid; RepositoryName = $Plan.RepositoryName
        RepositoryUri = $Plan.RepositoryUri; Scope = $Plan.Scope; ActiveVersion = $Plan.ActiveVersion
        InstalledVersion = $installed.Version; TargetVersion = $Plan.TargetVersion; InstalledPath = $installed.Path
        VerificationStatus = $VerificationStatus; RestartRequired = (Test-RestartRequired $Plan $Outcome)
        DependencySummary = @($Plan.DependencySummary); RecoveryStatus = 'NotRequired'; RecoveryGuidance = ''
    }
}
