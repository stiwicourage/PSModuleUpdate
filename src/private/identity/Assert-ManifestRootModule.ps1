function Assert-ManifestRootModule {
    param([hashtable]$Data, [string]$ManifestPath)
    if (-not $Data['RootModule']) { return }
    $root = Split-Path -Parent $ManifestPath
    $path = Assert-SafePath (Join-Path $root $Data['RootModule'])
    $relative = [IO.Path]::GetRelativePath($root, $path)
    if ($relative.StartsWith('..') -or [IO.Path]::IsPathRooted($relative)) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The declared root module must remain inside the package directory.'
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-PMUError 'PMU.ModuleIdentityMismatch' 'The declared root module is missing from the extracted package.'
    }
}
