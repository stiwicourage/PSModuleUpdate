function Initialize-StagedPackage {
    param([object]$Operation)
    Write-InstallationPhase $Operation.Plan 'Staging'
    Clear-StagingRoot $Operation
    Initialize-ControlledDirectory $Operation.StageRoot
    Assert-NativeRepositoryBinding $Operation
    Save-ProviderResource $Operation
    Get-ValidatedStagedTree $Operation
}
