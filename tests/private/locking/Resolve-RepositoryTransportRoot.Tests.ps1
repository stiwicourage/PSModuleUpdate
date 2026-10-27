BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Resolve-RepositoryTransportRoot' -Tag 'PMUUriBridge' {
    Context 'Shared per-user provider store boundary' {
        It 'uses actual LocalApplicationData rather than an installation scope or HOME override' {
            $expected = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PSModuleUpdate/RepositoryTransport'
            Resolve-RepositoryTransportRoot | Should -Be (Assert-SafePath $expected)
        }
        It 'aligns each HOME-only child lease root with its actual provider store and platform data directory' {
            $first = Get-PMUNativeRegistryRootProbe (Join-Path $TestDrive 'first-home')
            $second = Get-PMUNativeRegistryRootProbe (Join-Path $TestDrive 'second-home')
            $first.Home | Should -Not -Be $second.Home
            foreach ($probe in @($first, $second)) {
                $expectedData = [Environment]::GetFolderPath('LocalApplicationData')
                if ($IsLinux) {
                    $expectedData = Join-Path $probe.Home '.local/share'
                }
                $probe.LocalData | Should -Be $expectedData
                $probe.Store | Should -Be (Join-Path $expectedData 'PSResourceGet/PSResourceRepository.xml')
                $probe.Root | Should -Be (Join-Path $expectedData 'PSModuleUpdate/RepositoryTransport')
            }
        }
        It 'shares one lease root when distinct HOME children share the actual provider data store' {
            $data = Join-Path $TestDrive 'shared-data'
            $first = Get-PMUNativeRegistryRootProbe (Join-Path $TestDrive 'first-home') $data
            $second = Get-PMUNativeRegistryRootProbe (Join-Path $TestDrive 'second-home') $data
            $expectedData = [Environment]::GetFolderPath('LocalApplicationData')
            if ($IsLinux) {
                $expectedData = $data
            }
            $first.Home | Should -Not -Be $second.Home
            foreach ($probe in @($first, $second)) {
                $probe.LocalData | Should -Be $expectedData
                $probe.Store | Should -Be (Join-Path $expectedData 'PSResourceGet/PSResourceRepository.xml')
                $probe.Root | Should -Be (Join-Path $expectedData 'PSModuleUpdate/RepositoryTransport')
            }
            $first.Store | Should -Be $second.Store
            $first.Root | Should -Be $second.Root
        }
    }
}
