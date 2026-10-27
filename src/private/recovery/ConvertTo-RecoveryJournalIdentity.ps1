function ConvertTo-RecoveryJournalIdentity {
    param([object]$Plan)

    [ordered]@{
        SchemaVersion = 1
        TransactionId = [guid]::NewGuid().ToString('N')
        ModuleName = $Plan.ModuleName
        Scope = $Plan.Scope
        DestinationRoot = $Plan.DestinationRoot
        ModuleGuid = "$($Plan.ModuleGuid)"
        PreviousVersion = $Plan.InstalledVersion
        TargetVersion = $Plan.TargetVersion
        TargetNumericVersion = $Plan.TargetNumericVersion
        TargetPath = $Plan.TargetInstalledPath
    }
}
