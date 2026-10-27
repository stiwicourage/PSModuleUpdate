function Get-ManifestIdentity {
    param([string]$Path)
    $safe = Assert-SafePath $Path
    $data = Read-ManifestDefinition -ManifestPath $safe
    $version = Get-ManifestModuleVersion $data
    [pscustomobject]@{
        Name = [IO.Path]::GetFileNameWithoutExtension($safe)
        Guid = [guid]$data.GUID
        Version = $version
        ManifestPath = $safe
    }
}
