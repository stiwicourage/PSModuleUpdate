function Assert-NativeRecordField {
    param([object]$Metadata)
    foreach ($field in @('Name', 'Repository', 'RepositorySourceLocation', 'InstalledLocation')) {
        $property = $Metadata.PSObject.Properties[$field]
        if (-not $property -or -not [string]$property.Value) {
            Write-PMUError 'PMU.UnsupportedInstallation' 'The selected metadata is not a supported native installation.'
        }
    }
}
