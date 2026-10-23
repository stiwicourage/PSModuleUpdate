function Get-PlanDecisionField {
    param([object]$Context)
    $decision = Get-UpdateDecision $Context
    [ordered]@{
        UpdateAvailable = $decision.Available
        Disposition = $decision.Disposition
        Reason = $decision.Reason
        RestartRequired = $decision.Restart
        RequiresRepositoryTrust = -not $Context.Source.Trusted
        RequiresLicenseAcceptance = $Context.Target.RequiresLicenseAcceptance
        DependencySummary = @($Context.Target.Dependencies)
    }
}
