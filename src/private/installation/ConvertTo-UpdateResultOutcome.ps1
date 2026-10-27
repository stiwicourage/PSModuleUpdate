function ConvertTo-UpdateResultOutcome {
    param(
        [object]$Plan,
        [object]$Installed,
        [string]$Outcome,
        [string]$VerificationStatus
    )

    [ordered]@{
        InstalledVersion = $Installed.Version
        TargetVersion = $Plan.TargetVersion
        InstalledPath = $Installed.Path
        VerificationStatus = $VerificationStatus
        RestartRequired = (Test-RestartRequired $Plan $Outcome)
        DependencySummary = @($Plan.DependencySummary)
        RecoveryStatus = 'NotRequired'
        RecoveryGuidance = ''
    }
}
