function ConvertTo-FileTreeEntry {
    param(
        [IO.FileSystemInfo]$Item,
        [string]$RelativePath
    )

    $entry = [pscustomobject]@{
        Path = "$RelativePath/"
        Length = 0
        SHA256 = ''
    }
    if (-not $Item.PSIsContainer) {
        $entry.Path = $RelativePath
        $entry.Length = $Item.Length
        $entry.SHA256 = (Get-FileHash -LiteralPath $Item.FullName -Algorithm SHA256).Hash
    }
    $entry
}
