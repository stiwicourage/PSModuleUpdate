function Initialize-PMUInterruptedReplacement {
    param([object]$Plan)
    $operation = ConvertTo-InstallationOperation $Plan (Test-UpdatePlan $Plan) @{
        AcceptLicense = $true
        TrustRepository = $true
    } $null
    Initialize-ControlledDirectory $operation.WorkRoot
    $tree = @(Initialize-StagedPackage $operation)
    Initialize-Replacement $operation $tree
    Write-RecoveryJournalState $operation.Journal 'ReplacementInProgress'
    Remove-Item -LiteralPath $Plan.TargetInstalledPath -Recurse -Force
    $operation
}
