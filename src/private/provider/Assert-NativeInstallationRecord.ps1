function Assert-NativeInstallationRecord {
    param(
        [object]$Metadata,
        [object]$Operation,
        [string]$SelectedPath
    )

    Assert-NativeRecordField $Metadata
    if ($Metadata.Name -ine $Operation.Plan.ModuleName -or $Metadata.InstalledLocation -cne $SelectedPath) {
        Write-PMUError 'PMU.UnsupportedInstallation' 'Native metadata does not identify the selected installation.'
    }
    try {
        Assert-RepositoryName $Metadata.Repository
    } catch {
        Write-PMUError 'PMU.UnsupportedInstallation' 'The installed native repository name is unsupported.'
    }
}
