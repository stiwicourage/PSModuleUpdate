function Get-ManifestIdentity {
    param([string]$Path)
    $safe = Assert-SafePath $Path
    try { $data = Import-PowerShellDataFile -LiteralPath $safe -ErrorAction Stop }
    catch { Write-PMUError 'PMU.ModuleIdentityMismatch' 'The module manifest cannot be safely read.' }
    if (-not $data['GUID'] -or -not $data['ModuleVersion']) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The module manifest must declare version and GUID.'
    }
    Assert-ManifestRootModule $data $safe
    $version = Get-ManifestModuleVersion $data
    [pscustomobject]@{ Name = [IO.Path]::GetFileNameWithoutExtension($safe); Guid = [guid]$data.GUID; Version = $version; ManifestPath = $safe }
}
