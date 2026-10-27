function Assert-SurvivingManifestProperty {
    param(
        [object]$Actual,
        [object]$Expected,
        [string]$ErrorId
    )

    if (-not $Actual) {
        return
    }
    if ("$Actual" -ine $Expected) {
        Write-PMUError $ErrorId 'Recovery refuses to delete an installation with an unexpected manifest identity.'
    }
}
