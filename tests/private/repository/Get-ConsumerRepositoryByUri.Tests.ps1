BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-ConsumerRepositoryByUri' -Tag 'PMU', 'PMUStructuralRefinement' {
    BeforeEach {
        $script:consumerRepositories = @((Get-PMURepositoryEntry).Values)
        Mock Get-PSResourceRepository { $script:consumerRepositories }
        Mock Get-OwnedRepositoryName { 'OwnedFixture' }
    }
    It 'selects only an exact consumer endpoint, excluding owned transport registrations' {
        $script:consumerRepositories += [pscustomobject]@{
            Name = 'OwnedFixture'
            Uri = 'https://private.invalid/v3/index.json'
        }
        $script:consumerRepositories += [pscustomobject]@{
            Name = 'DifferentPathCase'
            Uri = 'https://private.invalid/v3/INDEX.json'
        }
        $selected = @(Get-ConsumerRepositoryByUri 'https://private.invalid/v3/index.json')
        $selected.Count | Should -Be 1
        $selected[0].Name | Should -Be 'PrivateFixture'
        $selected[0].Trusted | Should -BeFalse
    }
    It 'returns no consumer identity for an unregistered endpoint' {
        @(Get-ConsumerRepositoryByUri 'https://missing.invalid/v3/index.json').Count | Should -Be 0
    }
    It 'fails closed when multiple consumer identities share the endpoint' {
        $script:consumerRepositories += [pscustomobject]@{
            Name = 'AliasFixture'
            Uri = 'https://private.invalid/v3/index.json'
        }
        { Get-ConsumerRepositoryByUri 'https://private.invalid/v3/index.json' } |
            Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
    }
    It 'surfaces provider failure instead of treating the endpoint as unregistered' {
        Mock Get-PSResourceRepository { throw 'Fixture repository provider unavailable.' }
        { Get-ConsumerRepositoryByUri 'https://private.invalid/v3/index.json' } |
            Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
    }
}
