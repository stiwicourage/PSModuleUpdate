BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-ProviderDiscoveryParameter' -Tag 'PMU' {
    BeforeEach {
        $script:discoveryRequest = @{
            Name = 'FixtureModule'
            Repository = 'OwnedFeed'
            Version = $null
            Prerelease = $true
        }
    }
    It 'preserves the literal discovery query and omits an absent credential' {
        $parameters = Get-ProviderDiscoveryParameter $script:discoveryRequest $null
        $parameters.Name | Should -BeExactly 'FixtureModule'
        $parameters.Repository | Should -BeExactly 'OwnedFeed'
        $parameters.Prerelease | Should -BeTrue
        $parameters.ContainsKey('Credential') | Should -BeFalse
    }
    It 'defaults a false or empty requested version to all versions' -ForEach @(
        @{ RequestedVersion = $null }
        @{ RequestedVersion = '' }
        @{ RequestedVersion = $false }
    ) {
        $script:discoveryRequest.Version = $RequestedVersion
        (Get-ProviderDiscoveryParameter $script:discoveryRequest $null).Version | Should -BeExactly '*'
    }
    It 'preserves an explicit version, declined prereleases and credential identity' {
        $script:discoveryRequest.Version = '[1.0.0]'
        $script:discoveryRequest.Prerelease = $false
        $credential = [pscredential]::new('user', [securestring]::new())
        $parameters = Get-ProviderDiscoveryParameter $script:discoveryRequest $credential
        $parameters.Version | Should -BeExactly '[1.0.0]'
        $parameters.Prerelease | Should -BeFalse
        [object]::ReferenceEquals($parameters.Credential, $credential) | Should -BeTrue
    }
    It 'returns independent maps with the existing provider diagnostic policy' {
        $first = Get-ProviderDiscoveryParameter $script:discoveryRequest $null
        $second = Get-ProviderDiscoveryParameter $script:discoveryRequest $null
        $first | Should -BeOfType [hashtable]
        $first.ErrorAction | Should -BeExactly 'Stop'
        $first.WarningAction | Should -BeExactly 'SilentlyContinue'
        $first.Verbose | Should -BeFalse
        $first.Debug | Should -BeFalse
        $first.Name = 'CallerChanged'
        $second.Name | Should -BeExactly 'FixtureModule'
        [object]::ReferenceEquals($first, $second) | Should -BeFalse
    }
}
