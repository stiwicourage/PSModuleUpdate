function Get-FileTreeInventory {
    param([string]$Path)
    $root = Assert-SafePath $Path
    foreach ($item in Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction Stop | Sort-Object FullName -CaseSensitive) {
        $null = Assert-SafePath $item.FullName
        $relative = [IO.Path]::GetRelativePath($root, $item.FullName).Replace('\', '/')
        if ($item.PSIsContainer) {
            [pscustomobject]@{ Path = "$relative/"; Length = 0; SHA256 = '' }
            continue
        }
        # PSResourceGet intentionally generates this root-level installation metadata file.
        if ($relative -ceq 'PSGetModuleInfo.xml') { continue }
        [pscustomobject]@{ Path = $relative; Length = $item.Length; SHA256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }
    }
}
