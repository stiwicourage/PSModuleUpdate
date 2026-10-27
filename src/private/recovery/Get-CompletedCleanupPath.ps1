function Get-CompletedCleanupPath {
    param(
        [object]$Operation,
        [object]$Journal
    )

    $Operation.StageRoot
    $Operation.BackupPath
    if ($Journal.PSObject.Properties['TransactionId']) {
        Get-NativeProviderRoot $Operation $Journal
    }
}
