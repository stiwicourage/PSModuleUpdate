function Complete-PlanningContext {
    param(
        [object]$Context,
        [string]$RepositoryName,
        [pscredential]$Credential
    )

    $state = Get-PlanningInstallationState $Context.Module.Name $Context.Policy.Scope $Context.Reference.Guid
    Assert-ReferenceInstallationLayout $Context.Reference $state.Observed $state.RecoveryJournal
    $target = Get-PlanningUpdateTarget $Context $RepositoryName $Credential
    $Context | Add-Member -NotePropertyMembers @{
        Observed = $state.Observed
        Installed = $state.Installed
        InstalledTree = $state.InstalledTree
        Target = $target
    }
    $Context
}
