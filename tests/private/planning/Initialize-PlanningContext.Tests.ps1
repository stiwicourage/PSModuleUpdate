BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Initialize-PlanningContext' -Tag 'PMUUriBridge' {
    Context 'Source resolution before temporary transport' {
        It 'preserves independent target and policy inputs without finding packages' {
            $fixture = Initialize-PMURepositoryFixture $TestDrive
            Mock Get-ProviderContext { [pscustomobject]@{ Version = [version]'1.2.0' } }
            Mock Get-SelectedRepository { [pscustomobject]@{
                    Name = $null
                    Uri = 'https://transport.invalid'
                } }
            $context = Initialize-PlanningContext $fixture.Module ([pscustomobject]@{ Uri = [uri]'https://transport.invalid' }) @{}
            $context.Module.Guid | Should -Be $fixture.Guid
            $context.Policy.Scope | Should -Be CurrentUser
        }
    }
}
