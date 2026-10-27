function Get-PlanningRecoveryJournal {
    param(
        [string]$Name,
        [string]$Scope,
        [guid]$Guid
    )

    $root = Resolve-ModuleInstallationRoot $Scope
    $identity = [pscustomobject]@{
        ModuleName = $Name
        ModuleGuid = $Guid
        Scope = $Scope
        DestinationRoot = $root
        TargetNumericVersion = '0.0.0'
    }
    $operation = ConvertTo-InstallationOperation $identity $null @{} $null
    Read-RecoveryJournal $operation
}
