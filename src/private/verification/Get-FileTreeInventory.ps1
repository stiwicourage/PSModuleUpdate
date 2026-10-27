function Get-FileTreeInventory {
    param([string]$Path)
    $root = Assert-SafePath $Path
    foreach ($item in Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction Stop | Sort-Object FullName -CaseSensitive) {
        $null = Assert-SafePath $item.FullName
        $relative = [IO.Path]::GetRelativePath($root, $item.FullName).Replace('\', '/')
        # PSResourceGet intentionally generates this root-level installation metadata file.
        if (-not $item.PSIsContainer -and $relative -ceq 'PSGetModuleInfo.xml') {
            continue
        }
        ConvertTo-FileTreeEntry -Item $item -RelativePath $relative
    }
}
