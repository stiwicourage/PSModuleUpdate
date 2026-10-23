BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Find-ProviderResource' -Tag 'PMU' {
    It 'enumerates all eligible versions from only the literal source' {
        Mock Find-PSResource {}
        Find-ProviderResource @{ Name = 'FixtureModule'; Repository = 'OwnedFeed'; Version = $null; Prerelease = $true } $null
        Should -Invoke Find-PSResource -Times 1 -ParameterFilter { $Version -eq '*' -and $Repository.Count -eq 1 -and $Repository[0] -eq 'OwnedFeed' }
    }
}
