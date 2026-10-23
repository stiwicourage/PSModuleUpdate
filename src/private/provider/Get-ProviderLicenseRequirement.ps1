function Get-ProviderLicenseRequirement {
    param([object]$Resource)
    $metadata = $Resource.AdditionalMetadata
    if (-not $metadata) { return $true }
    $keys = @($metadata.Keys | Where-Object { $_ -ieq 'RequireLicenseAcceptance' })
    if ($keys.Count -ne 1) { return $true }
    $value = $metadata[$keys[0]]
    if ($value -is [bool]) { return $value }
    if ($value -isnot [string]) { return $true }
    $value -ine 'false'
}
