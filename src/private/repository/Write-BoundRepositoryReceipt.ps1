function Write-BoundRepositoryReceipt {
    param([object]$Lease)
    $path = Assert-SafePath $Lease.ReceiptPath
    $temporary = Write-RepositoryReceipt $Lease.Receipt $Lease.Root '.binding'
    try { [IO.File]::Move($temporary, $path, $true) }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -ErrorAction Stop }
    }
}
