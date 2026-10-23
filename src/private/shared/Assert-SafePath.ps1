function Assert-SafePath {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                Write-PMUError 'PMU.UnsupportedInstallation' 'Symbolic links and reparse points are not supported in controlled paths.'
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    $full.TrimEnd([IO.Path]::DirectorySeparatorChar)
}
