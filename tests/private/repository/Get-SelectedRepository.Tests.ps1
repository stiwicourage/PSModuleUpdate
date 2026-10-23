BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-SelectedRepository' -Tag 'PMU', 'PMURepositoryUri' {
    Context 'Mutually exclusive source selectors' {
        It 'routes a URI without falling back to the name resolver' {
            Mock Get-RepositorySnapshotByUri { @{ Name = 'ResolvedFixture' } }
            Mock Get-RepositorySnapshot { throw 'Name fallback is prohibited.' }
            (Get-SelectedRepository @{ Name = $null; Uri = [uri]'https://feed.invalid/v3/index.json' }).Name | Should -Be 'ResolvedFixture'
            Should -Invoke Get-RepositorySnapshot -Times 0
        }
        It 'preserves registered-name selection' {
            Mock Get-RepositorySnapshot { @{ Name = 'NamedFixture' } }
            (Get-SelectedRepository @{ Name = 'NamedFixture'; Uri = $null }).Name | Should -Be 'NamedFixture'
        }
    }
}
