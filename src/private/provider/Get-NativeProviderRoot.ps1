function Get-NativeProviderRoot {
    param(
        [object]$Operation,
        [object]$Journal = $Operation.Journal
    )

    if (-not $Journal -or -not $Journal.PSObject.Properties['TransactionId']) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'A native provider root requires its original transaction nonce.'
    }
    Join-Path $Operation.WorkRoot "native-$($Journal.TransactionId)"
}
