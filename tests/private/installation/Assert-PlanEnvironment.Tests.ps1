BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-PlanEnvironment' -Tag 'PMU' {
    It 'rejects destination drift without attempting a fallback' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Get-ProviderContext { @{ Version = [version]'1.2.0' } }
        Mock Get-RepositorySnapshot { @{ Name = 'OwnedFeed'; Uri = 'https://example.invalid/feed'; ApiVersion = 'V3'; Trusted = $true } }
        Mock Resolve-ModuleInstallationRoot { '/different/root' }
        { Assert-PlanEnvironment $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
}
