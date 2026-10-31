BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-NativeProviderContext' -Tag 'PMU', 'PMUTargetManifest' {
    It 'retains owned provider root and original CurrentUser destination' {
        Mock Get-NativeProviderRoot {
            'owned'
        }
        Mock Resolve-ModuleInstallationRoot {
            'original-user-modules'
        }
        $result = ConvertTo-NativeProviderContext ([pscustomobject]@{
            })
        $result.Root | Should -Be owned
        $result.CurrentUserRoot | Should -Be original-user-modules
        $result.Paths | Should -BeNullOrEmpty
    }
}
