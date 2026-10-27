BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-RepositorySnapshot' -Tag 'PMU' {
    It 'projects the validated provider result through the repository adapter' {
        Mock Get-SingleProviderRepository { [pscustomobject]@{
                Name = 'OwnedFeed'
                Uri = [uri]'https://feed.invalid'
                ApiVersion = 'V3'
                Trusted = $false
            } }
        $snapshot = Get-RepositorySnapshot 'OwnedFeed'
        Should -Invoke Get-SingleProviderRepository -Times 1 -Exactly -ParameterFilter { $Name -ceq 'OwnedFeed' }
        @($snapshot.PSObject.Properties.Name) | Should -Be @('Name', 'Uri', 'ApiVersion', 'Trusted')
        $snapshot.Name | Should -BeExactly 'OwnedFeed'
        $snapshot.Uri | Should -Be ([uri]'https://feed.invalid')
        $snapshot.ApiVersion | Should -BeExactly 'V3'
        $snapshot.Trusted | Should -BeFalse
    }
    It 'rejects a literal name that resolves to a repointed endpoint' {
        Mock Get-PSResourceRepository { [pscustomobject]@{
                Name = 'OwnedFeed'
                Uri = [uri]'https://other.invalid'
                ApiVersion = 'V3'
                Trusted = $false
            } }
        { Get-RepositorySnapshot 'OwnedFeed' ([uri]'https://expected.invalid') } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }
    It 'reports an unavailable provider repository store' {
        Mock Get-PSResourceRepository { throw 'store offline' }
        { Get-RepositorySnapshot 'OwnedFeed' } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
    }
}
