function Test-InstallationDirectoryCandidate {
    param([System.IO.DirectoryInfo]$Directory, [string]$Name)
    $manifest = Join-Path $Directory.FullName "$Name.psd1"
    $Directory.Name -match '^[0-9]+\.[0-9]+(?:\.[0-9]+){0,2}$' -or (Test-Path -LiteralPath $manifest)
}
