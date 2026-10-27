function Get-RecoveryJournalField {
    param([object]$Journal)
    $fields = 'SchemaVersion ModuleName Scope DestinationRoot ModuleGuid PreviousVersion TargetVersion TargetNumericVersion TargetPath JournalPath StageRoot StagedPath BackupPath Reinstall State RecoveryStatus StagedTree BackupTree'.Split(' ')
    if ($Journal.PSObject.Properties['TransactionId']) {
        Assert-RecoveryTransactionId $Journal.TransactionId
        $fields += 'TransactionId'
    }
    $fields
}
