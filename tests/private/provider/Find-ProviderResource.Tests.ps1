BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Find-ProviderResource' -Tag 'PMU' {
    It 'defaults a false or empty requested version to all versions' -ForEach @(
        @{ RequestedVersion = '' }
        @{ RequestedVersion = $false }
    ) {
        Mock Find-PSResource {}
        Find-ProviderResource @{
            Name = 'FixtureModule'
            Repository = 'OwnedFeed'
            Version = $RequestedVersion
            Prerelease = $false
        } $null
        Should -Invoke Find-PSResource -Times 1 -ParameterFilter {
            $Version -eq '*' -and $ErrorAction -eq 'Stop' -and
            $WarningAction -eq 'SilentlyContinue' -and -not $Verbose -and -not $Debug
        }
    }
    It 'enumerates all eligible versions from only the literal source' {
        Mock Find-PSResource {}
        Find-ProviderResource @{
            Name = 'FixtureModule'
            Repository = 'OwnedFeed'
            Version = $null
            Prerelease = $true
        } $null
        Should -Invoke Find-PSResource -Times 1 -ParameterFilter { $Version -eq '*' -and $Repository.Count -eq 1 -and $Repository[0] -eq 'OwnedFeed' }
    }
    It 'passes an explicit version and credential to the provider' {
        Mock Find-PSResource {}
        $credential = [pscredential]::new('user', [securestring]::new())
        Find-ProviderResource @{
            Name = 'FixtureModule'
            Repository = 'OwnedFeed'
            Version = '[1.0.0]'
            Prerelease = $false
        } $credential
        Should -Invoke Find-PSResource -Times 1 -ParameterFilter { $Version -eq '[1.0.0]' -and $Credential.UserName -eq 'user' }
    }
    It 'reports provider discovery failures with a stable error id' {
        Mock Find-PSResource { throw 'feed offline' }
        { Find-ProviderResource @{
                Name = 'FixtureModule'
                Repository = 'OwnedFeed'
                Version = $null
                Prerelease = $false
            } $null } | Should -Throw -ErrorId 'PMU.DiscoveryFailed'
    }
    Context 'provider boundary outcomes' {
        BeforeEach {
            $script:discoveryRequest = @{
                Name = 'FixtureModule'
                Repository = 'OwnedFeed'
                Version = $null
                Prerelease = $false
            }
        }
        It 'returns the original provider objects in order' {
            $resources = @([pscustomobject]@{ Version = '1.0.0' }, [pscustomobject]@{ Version = '2.0.0' })
            Mock Find-PSResource { $resources }
            $actual = @(Find-ProviderResource $script:discoveryRequest $null)
            $actual.Count | Should -Be 2
            [object]::ReferenceEquals($actual[0], $resources[0]) | Should -BeTrue
            [object]::ReferenceEquals($actual[1], $resources[1]) | Should -BeTrue
        }
        It 'preserves an empty successful provider result' {
            Mock Find-PSResource { @() }
            @(Find-ProviderResource $script:discoveryRequest $null).Count | Should -Be 0
        }
        It 'normalizes structured <ProviderId> without exposing provider diagnostics' -Tag 'PMUPackageNotFound' -ForEach @(
            @{ ProviderId = 'PackageNotFound' }
            @{ ProviderId = 'PackageNotFound,Microsoft.PowerShell.PSResourceGet.Cmdlets.FindPSResource' }
        ) {
            Mock Find-PSResource { throw (Get-PMUTestProviderFailure $ProviderId) }
            $failure = { Find-ProviderResource $script:discoveryRequest $null } |
                Should -Throw -ErrorId 'PMU.PackageNotFound' -PassThru
            ($failure | Out-String) | Should -Not -Match 'provider-secret-fixture|credential-user-fixture'
            ($failure.TargetObject | ConvertTo-Json) | Should -Not -Match 'provider-secret-fixture|credential-user-fixture'
            Should -Invoke Find-PSResource -Times 1 -Exactly -ParameterFilter { $ErrorAction -eq 'Stop' -and $Repository[0] -eq 'OwnedFeed' }
        }
        It 'retains <ExpectedId> for unrelated structured ID <ProviderId>' -Tag 'PMUPackageNotFound' -ForEach @(
            @{ ProviderId = 'OtherMissingResource'; Category = 'ObjectNotFound'; Message = 'PackageNotFound: no package found'; ExpectedId = 'PMU.DiscoveryFailed' }
            @{ ProviderId = 'PrefixPackageNotFound'; Category = 'ObjectNotFound'; Message = 'no package found'; ExpectedId = 'PMU.DiscoveryFailed' }
            @{ ProviderId = 'PackageNotFoundExtra'; Category = 'ObjectNotFound'; Message = 'no package found'; ExpectedId = 'PMU.DiscoveryFailed' }
            @{ ProviderId = 'packagenotfound'; Category = 'ObjectNotFound'; Message = 'no package found'; ExpectedId = 'PMU.DiscoveryFailed' }
            @{ ProviderId = 'OtherError,PackageNotFound'; Category = 'ObjectNotFound'; Message = 'no package found'; ExpectedId = 'PMU.DiscoveryFailed' }
            @{ ProviderId = 'NetworkFailure'; Category = 'ConnectionError'; Message = 'feed offline'; ExpectedId = 'PMU.DiscoveryFailed' }
            @{ ProviderId = 'AuthenticationFailure'; Category = 'SecurityError'; Message = '401 authentication failed'; ExpectedId = 'PMU.AuthenticationFailed' }
            @{ ProviderId = 'PermissionFailure'; Category = 'PermissionDenied'; Message = 'permission denied'; ExpectedId = 'PMU.PermissionDenied' }
        ) {
            Mock Find-PSResource { throw (Get-PMUTestProviderFailure $ProviderId "$Message provider-secret-fixture" $Category) }
            $failure = { Find-ProviderResource $script:discoveryRequest $null } |
                Should -Throw -ErrorId $ExpectedId -PassThru
            ($failure | Out-String) | Should -Not -Match 'provider-secret-fixture'
            Should -Invoke Find-PSResource -Times 1 -Exactly -ParameterFilter { $ErrorAction -eq 'Stop' }
        }
    }
}
