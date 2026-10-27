function Invoke-ProviderInstallation {
    param(
        [object]$Operation,
        [object[]]$StagedTree
    )

    Write-RecoveryJournalState $Operation.Journal 'ReplacementInProgress'
    try {
        Write-InstallationPhase $Operation.Plan 'Replacing'
        Assert-NativeRepositoryBinding $Operation
        Install-ProviderResource $Operation
        Write-RecoveryJournalState $Operation.Journal 'Verification'
        Write-InstallationPhase $Operation.Plan 'Verifying'
        Assert-InstalledPackage $Operation $StagedTree
    } catch {
        Resolve-InstallationFailure $Operation $_
    }
}
