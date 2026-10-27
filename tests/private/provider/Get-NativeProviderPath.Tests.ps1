BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeProviderPath' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'fails closed when the qualified native runtime is not loaded' {
        Mock Get-Module { @() }
        { Get-NativeProviderPath } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
    It 'reads actual native module-scope paths rather than assuming environment overrides work' {
        $script:pathFixtureModule = New-Module -Name DisposableNativePaths -ScriptBlock {
            $script:PSGetModuleSourcesFilePath = 'actual-store'
            $script:PSGetSettingsFilePath = 'actual-settings'
            $script:PSGetProgramDataPath = 'actual-config'
            $script:PSGetPath = @{
                CurrentUserModules = 'actual-user'
                AllUsersModules = 'actual-all'
            }
        }
        Add-Member -InputObject $pathFixtureModule -MemberType NoteProperty -Name Version -Value ([version]'2.2.5') -Force
        Mock Get-Module { $script:pathFixtureModule }
        $paths = Get-NativeProviderPath
        $paths.Store | Should -BeExactly 'actual-store'
        $paths.Settings | Should -BeExactly 'actual-settings'
        $paths.Config | Should -BeExactly 'actual-config'
        $paths.CurrentUser | Should -BeExactly 'actual-user'
        $paths.AllUsers | Should -BeExactly 'actual-all'
    }
}
