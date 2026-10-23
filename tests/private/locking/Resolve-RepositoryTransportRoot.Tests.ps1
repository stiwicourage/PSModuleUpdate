BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-RepositoryTransportRoot' -Tag 'PMUUriBridge' {
    Context 'Shared per-user provider store boundary' {
        It 'uses actual LocalApplicationData rather than an installation scope or HOME override' {
            $expected = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PSModuleUpdate/RepositoryTransport'
            Resolve-RepositoryTransportRoot | Should -Be (Assert-SafePath $expected)
        }
        It 'resolves the same native registry lease root from two distinct child HOME directories' {
            $first = Get-PMUNativeRegistryRootProbe (Join-Path $TestDrive 'first-home')
            $second = Get-PMUNativeRegistryRootProbe (Join-Path $TestDrive 'second-home')
            $first.Home | Should -Not -Be $second.Home
            $first.Root | Should -Be $second.Root
            $first.Root | Should -Be (Resolve-RepositoryTransportRoot)
        }
    }
}
