function Compare-PrereleaseLabel {
    param(
        [string]$Left,
        [string]$Right
    )

    if ($Left -ceq $Right) {
        return 0
    }
    if (-not $Left) {
        return 1
    }
    if (-not $Right) {
        return -1
    }
    Compare-PrereleaseSegmentList $Left.Split('.') $Right.Split('.')
}
