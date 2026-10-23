function Assert-RecoveryJournalSchema {
    param([object]$Journal)
    $fields = 'SchemaVersion ModuleName Scope DestinationRoot ModuleGuid PreviousVersion TargetVersion TargetNumericVersion TargetPath JournalPath StageRoot StagedPath BackupPath Reinstall State RecoveryStatus StagedTree BackupTree'.Split(' ')
    $actual = @($Journal.PSObject.Properties.Name | Sort-Object)
    if (($actual -join '|') -cne (($fields | Sort-Object) -join '|')) {
        Write-PMUError 'PMU.RecoveryRequired' 'The recovery journal schema is invalid.'
    }
    if ($Journal.Reinstall -isnot [bool]) { Write-PMUError 'PMU.RecoveryRequired' 'The recovery journal mutation flag is not Boolean.' }
    if ($Journal.StagedTree -isnot [array]) { Write-PMUError 'PMU.RecoveryRequired' 'The recovery reference tree is not an array.' }
    if ($Journal.BackupTree -isnot [array]) { Write-PMUError 'PMU.RecoveryRequired' 'The recovery backup tree is not an array.' }
}
