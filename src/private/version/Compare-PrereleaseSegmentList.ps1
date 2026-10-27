function Compare-PrereleaseSegmentList {
    param(
        [string[]]$Left,
        [string[]]$Right
    )

    for ($index = 0; $index -lt [Math]::Min($Left.Count, $Right.Count); $index++) {
        $comparison = Compare-PrereleaseIdentifier $Left[$index] $Right[$index]
        if ($comparison) {
            return $comparison
        }
    }
    [Math]::Sign($Left.Count - $Right.Count)
}
