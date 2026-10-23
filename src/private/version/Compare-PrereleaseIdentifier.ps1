function Compare-PrereleaseIdentifier {
    param([string]$Left, [string]$Right)
    $leftNumeric = $Left -match '^\d+$'
    $rightNumeric = $Right -match '^\d+$'
    if ($leftNumeric -and $rightNumeric) {
        return [Math]::Sign(([System.Numerics.BigInteger]::Parse($Left)).CompareTo([System.Numerics.BigInteger]::Parse($Right)))
    }
    if ($leftNumeric -ne $rightNumeric) {
        if ($leftNumeric) { return -1 }
        return 1
    }
    [Math]::Sign([string]::CompareOrdinal($Left, $Right))
}
