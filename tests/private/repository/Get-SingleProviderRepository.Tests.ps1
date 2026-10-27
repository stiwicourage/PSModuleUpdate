BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-SingleProviderRepository' -Tag 'PMU' {
    It 'forwards the original name unchanged and returns the provider object for <LookupName>' -ForEach @(
        @{ LookupName = 'oWnEdFeed' }
        @{ LookupName = 'Owned*' }
    ) {
        $repository = [pscustomobject]@{ Name = 'OwnedFeed'; Uri = [uri]'https://feed.invalid' }
        Mock Get-PSResourceRepository { $repository }
        $result = Get-SingleProviderRepository $LookupName
        [object]::ReferenceEquals($result, $repository) | Should -BeTrue
        Should -Invoke Get-PSResourceRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq $LookupName -and $ErrorAction -eq 'Stop'
        }
    }
    It 'requires exactly one provider result when the count is <Count>' -ForEach @(
        @{ Count = 0 }
        @{ Count = 2 }
    ) {
        Mock Get-PSResourceRepository {
            for ($index = 0; $index -lt $Count; $index++) {
                [pscustomobject]@{ Name = "Feed$index" }
            }
        }
        { Get-SingleProviderRepository 'Owned*' } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable' -ExpectedMessage '*Exactly one registered repository is required.*'
    }
    It 'reports an unavailable provider repository store' {
        Mock Get-PSResourceRepository { throw 'store offline' }
        { Get-SingleProviderRepository 'OwnedFeed' } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
    }
}
