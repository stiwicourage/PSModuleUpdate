function Initialize-PMURecoveryFixture {
    param([string]$Root)
    $operation = Initialize-PMUTestOperation $Root
    Initialize-ControlledDirectory $operation.WorkRoot
    $stage = Initialize-PMUTestPackage $operation.StageRoot '2.0.0-preview.2'
    $tree = @(Get-FileTreeInventory $stage)
    Initialize-Replacement $operation $tree
    Write-RecoveryJournalState $operation.Journal 'ReplacementInProgress'
    $operation
}
