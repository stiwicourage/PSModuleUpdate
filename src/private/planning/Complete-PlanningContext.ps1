function Complete-PlanningContext {
    param([object]$Context, [string]$RepositoryName, [pscredential]$Credential)
    $state = Get-PlanningInstallationState $Context.Module.Name $Context.Policy.Scope $Context.Reference.Guid
    Assert-ReferenceInstallationLayout $Context.Reference $state.Observed $state.RecoveryJournal
    $request = @{ Name = $Context.Module.Name; Repository = $RepositoryName; Prerelease = $Context.Policy.Channel -eq 'IncludePrerelease'; Version = $Context.Policy.VersionRange }
    $releases = @(Find-ProviderResource $request $Credential | ForEach-Object { ConvertTo-ProviderRelease $_ })
    $target = Select-UpdateTarget $releases $Context.Policy.Channel
    $Context | Add-Member -NotePropertyMembers @{ Observed = $state.Observed; Installed = $state.Installed; InstalledTree = $state.InstalledTree; Target = $target }
    $Context
}
