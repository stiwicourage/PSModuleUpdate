function Get-ExpectedRecoveryJournalIdentity {
    param(
        [object]$Plan,
        [object]$Version
    )

    [pscustomobject]@{
        SchemaVersion = 1
        ModuleName = $Plan.ModuleName
        ModuleGuid = "$($Plan.ModuleGuid)"
        Scope = $Plan.Scope
        DestinationRoot = $Plan.DestinationRoot
        TargetNumericVersion = $Version.NumericVersion
    }
}
