function Initialize-Replacement {
    param([object]$Operation, [object[]]$Tree)
    $path = $Operation.Plan.TargetInstalledPath
    $Operation.Reinstall = Test-Path -LiteralPath $path
    if ($Operation.Reinstall) {
        $identity = Get-ManifestIdentity (Join-Path $path "$($Operation.Plan.ModuleName).psd1")
        if ($identity.Guid -ne $Operation.Plan.ModuleGuid) { Write-PMUError 'PMU.GuidMismatch' 'Refusing to replace a different GUID.' }
    }
    $Operation.Journal = ConvertTo-RecoveryJournal $Operation $Tree
    Write-RecoveryJournalState $Operation.Journal 'Preparation'
    if ($Operation.Reinstall) { Copy-InstallationBackup $Operation }
}
