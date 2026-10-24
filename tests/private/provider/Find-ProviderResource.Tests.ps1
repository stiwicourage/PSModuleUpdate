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
    It 'passes an explicit version and credential to the provider' {
        Mock Find-PSResource {}
        $credential = [pscredential]::new('user', [securestring]::new())
        Find-ProviderResource @{ Name = 'FixtureModule'; Repository = 'OwnedFeed'; Version = '[1.0.0]'; Prerelease = $false } $credential
        Should -Invoke Find-PSResource -Times 1 -ParameterFilter { $Version -eq '[1.0.0]' -and $Credential.UserName -eq 'user' }
    }
    It 'reports provider discovery failures with a stable error id' {
        Mock Find-PSResource { throw 'feed offline' }
        { Find-ProviderResource @{ Name = 'FixtureModule'; Repository = 'OwnedFeed'; Version = $null; Prerelease = $false } $null } | Should -Throw -ErrorId 'PMU.DiscoveryFailed'
    }
}
