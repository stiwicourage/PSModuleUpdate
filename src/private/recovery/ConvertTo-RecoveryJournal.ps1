function ConvertTo-RecoveryJournal {
    param([object]$Operation, [object[]]$StagedTree)
    $plan = $Operation.Plan
    [pscustomobject]@{
        SchemaVersion = 1; ModuleName = $plan.ModuleName; Scope = $plan.Scope; DestinationRoot = $plan.DestinationRoot
        ModuleGuid = "$($plan.ModuleGuid)"; PreviousVersion = $plan.InstalledVersion; TargetVersion = $plan.TargetVersion
        TargetNumericVersion = $plan.TargetNumericVersion; TargetPath = $plan.TargetInstalledPath
        JournalPath = $Operation.JournalPath; StageRoot = $Operation.StageRoot; StagedPath = $Operation.StagedPath
        BackupPath = $Operation.BackupPath; Reinstall = $Operation.Reinstall
        State = 'Preparation'; RecoveryStatus = 'NotRequired'; StagedTree = @($StagedTree); BackupTree = @()
    }
}
