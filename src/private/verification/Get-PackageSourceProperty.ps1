function Get-PackageSourceProperty {
    param([string]$Path)
    $metadataPath = Join-Path $Path 'PSGetModuleInfo.xml'
    if (-not (Test-Path -LiteralPath $metadataPath)) {
        return
    }
    try {
        $metadata = Import-Clixml -LiteralPath $metadataPath -ErrorAction Stop
    } catch {
        Write-PMUError 'PMU.VerificationFailed' 'Provider source metadata is unreadable.'
    }
    $metadata.PSObject.Properties['RepositorySourceLocation']
}
