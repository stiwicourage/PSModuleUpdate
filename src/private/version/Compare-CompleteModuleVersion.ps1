function Compare-CompleteModuleVersion {
    param([string]$Left, [string]$Right)
    $a = ConvertTo-CompleteModuleVersion $Left
    $b = ConvertTo-CompleteModuleVersion $Right
    $comparison = ([version]$a.NumericVersion).CompareTo([version]$b.NumericVersion)
    if ($comparison) { return [Math]::Sign($comparison) }
    Compare-PrereleaseLabel $a.Prerelease $b.Prerelease
}
