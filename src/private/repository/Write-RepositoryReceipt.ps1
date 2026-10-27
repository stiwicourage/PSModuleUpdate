function Write-RepositoryReceipt {
    param(
        [object]$Receipt,
        [string]$Root,
        [string]$Suffix = ''
    )

    $path = Assert-SafePath (Join-Path $Root "$($Receipt.OperationId).json$Suffix")
    $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $Receipt -Depth 4 -Compress))
    $options = Get-RepositoryReceiptStreamOption
    $stream = [IO.FileStream]::new($path, $options)
    try {
        $stream.Write($bytes)
        $stream.Flush($true)
    } finally {
        $stream.Dispose()
    }
    $path
}
