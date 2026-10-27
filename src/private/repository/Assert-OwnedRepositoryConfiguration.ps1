function Assert-OwnedRepositoryConfiguration {
    param(
        [object]$Registration,
        [object]$Receipt
    )

    $actual = [pscustomobject]@{
        RegistrationName = $Registration.Name
        UriHash = Get-RepositoryUriHash ([uri]$Registration.Uri)
        ApiVersion = "$($Registration.ApiVersion)"
        Trusted = [bool]$Registration.Trusted
        Priority = $Registration.Priority
    }
    Assert-MatchingProperty $actual $Receipt @('RegistrationName', 'UriHash', 'ApiVersion', 'Trusted', 'Priority') 'PMU.RepositoryRecoveryRequired'
}
