BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-OwnedRepositoryRegisterParameter' -Tag 'PMU', 'PMUStructuralRefinement' {
    It 'forwards a known API but leaves provider discovery unbound for <ApiVersion>' -ForEach @(
        @{ ApiVersion = 'Unknown'; HasApi = $false }
        @{ ApiVersion = 'V2'; HasApi = $true }
        @{ ApiVersion = 'V3'; HasApi = $true }
    ) {
        $lease = [pscustomobject]@{
            Name = 'OwnedFixture'
            Source = [pscustomobject]@{ Uri = 'https://transport.invalid/v3/index.json' }
            Receipt = [pscustomobject]@{ ApiVersion = $ApiVersion }
            Trusted = $true
            Credential = [pscredential]::new('fixture', [securestring]::new())
            Force = $true
        }
        $parameters = Get-OwnedRepositoryRegisterParameter $lease
        $parameters.Name | Should -BeExactly 'OwnedFixture'
        $parameters.Uri | Should -BeExactly 'https://transport.invalid/v3/index.json'
        $parameters.ContainsKey('ApiVersion') | Should -Be $HasApi
        if ($HasApi) {
            $parameters.ApiVersion | Should -BeExactly $ApiVersion
        }
        foreach ($privateProperty in 'Trusted', 'Credential', 'CredentialInfo', 'Force') {
            $parameters.Keys | Should -Not -Contain $privateProperty
        }
    }
}
