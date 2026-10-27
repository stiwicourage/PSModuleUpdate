function ConvertTo-ProviderRelease {
    param([object]$Resource)
    $version = "$($Resource.Version)"
    if ($Resource.Prerelease) {
        $version += "-$($Resource.Prerelease)"
    }
    $identity = ConvertTo-CompleteModuleVersion $version
    $license = Get-ProviderLicenseRequirement $Resource
    [pscustomobject]@{
        Name = $Resource.Name
        Version = $identity
        RequiresLicenseAcceptance = $license
        Dependencies = @($Resource.Dependencies | ForEach-Object { "$($_.Name)" })
    }
}
