function Get-PlanningInstallationState {
    param(
        [string]$Name,
        [string]$Scope,
        [guid]$Guid
    )

    $state = Get-RecoveryAwareInstallation $Name $Scope $Guid
    $otherScope = 'AllUsers'
    if ($Scope -eq 'AllUsers') {
        $otherScope = 'CurrentUser'
    }
    $observed = @($state.Selected
        Get-InstalledModuleIdentityList $Name $otherScope)
    $snapshot = Get-PlanningInstallationSnapshot $state
    [pscustomobject]@{
        Observed = $observed
        Installed = $snapshot.Installed
        InstalledTree = $snapshot.InstalledTree
        RecoveryJournal = $snapshot.RecoveryJournal
    }
}
