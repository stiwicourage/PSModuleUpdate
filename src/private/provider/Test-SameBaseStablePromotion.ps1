function Test-SameBaseStablePromotion {
    param([object]$Plan)
    if ($Plan.TargetIsPrerelease) {
        return $false
    }
    $installed = ConvertTo-CompleteModuleVersion $Plan.InstalledVersion
    if (-not $installed.IsPrerelease) {
        return $false
    }
    $installed.NumericVersion -ceq $Plan.TargetNumericVersion
}
