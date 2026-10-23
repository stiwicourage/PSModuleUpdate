function Assert-RecoveryPath {
    param([object]$Journal, [object]$Operation)
    $expected = @{
        JournalPath = $Operation.JournalPath; StageRoot = $Operation.StageRoot; BackupPath = $Operation.BackupPath
        StagedPath = Join-Path $Operation.StageRoot "$($Journal.ModuleName)/$($Journal.TargetNumericVersion)"
        TargetPath = Join-Path $Operation.Plan.DestinationRoot "$($Journal.ModuleName)/$($Journal.TargetNumericVersion)"
    }
    foreach ($key in $expected.Keys) {
        if ($Journal.$key -cne $expected[$key]) { Write-PMUError 'PMU.RecoveryRequired' 'Recovery paths are not the expected PMU-controlled paths.' }
        $null = Assert-SafePath $Journal.$key
    }
}
