function ConvertTo-CompleteModuleVersion {
    param([string]$Version)
    if ($Version -notmatch '^(?<numeric>\d+\.\d+(?:\.\d+){0,2})(?:-(?<label>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$') {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The module version has an unsupported form.'
    }
    $numeric = [version]$Matches.numeric
    $label = $Matches['label']
    if (@($label -split '\.' | Where-Object { $_ -match '^0\d+$' }).Count) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'Numeric prerelease identifiers cannot have leading zeros.'
    }
    [pscustomobject]@{ FullVersion = $Version; NumericVersion = $numeric.ToString(); Prerelease = "$label"; IsPrerelease = [bool]$label }
}
