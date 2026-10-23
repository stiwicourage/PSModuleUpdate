function Get-SurvivingManifestData {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @{} }
    try { Import-PowerShellDataFile -LiteralPath $Path -ErrorAction Stop }
    catch { @{} } # A provider interruption can leave a truncated manifest in a journal-owned path.
}
