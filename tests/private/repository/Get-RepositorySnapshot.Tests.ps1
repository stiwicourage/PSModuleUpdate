BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-RepositorySnapshot' -Tag 'PMU' {
    It 'rejects a literal name that resolves to a repointed endpoint' {
        Mock Get-PSResourceRepository { [pscustomobject]@{ Name = 'OwnedFeed'; Uri = [uri]'https://other.invalid'; ApiVersion = 'V3'; Trusted = $false } }
        { Get-RepositorySnapshot 'OwnedFeed' ([uri]'https://expected.invalid') } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }
    It 'reports an unavailable provider repository store' {
        Mock Get-PSResourceRepository { throw 'store offline' }
        { Get-RepositorySnapshot 'OwnedFeed' } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
    }
}
