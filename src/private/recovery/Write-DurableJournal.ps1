function Write-DurableJournal {
    param([object]$Journal)
    $path = Assert-SafePath $Journal.JournalPath
    $temporary = "$path.new"
    $null = Assert-SafePath $temporary
    $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $Journal -Depth 12 -Compress))
    $stream = [IO.File]::Open($temporary, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes); $stream.Flush($true) }
    finally { $stream.Dispose() }
    [IO.File]::Move($temporary, $path, $true)
}
