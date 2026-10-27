function ConvertTo-RecoveryJournalProgress {
    param(
        [object]$Operation,
        [object[]]$StagedTree
    )

    [ordered]@{
        JournalPath = $Operation.JournalPath
        StageRoot = $Operation.StageRoot
        StagedPath = $Operation.StagedPath
        BackupPath = $Operation.BackupPath
        Reinstall = $Operation.Reinstall
        State = 'Preparation'
        RecoveryStatus = 'NotRequired'
        StagedTree = @($StagedTree)
        BackupTree = @()
    }
}
