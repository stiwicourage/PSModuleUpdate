BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ActiveModuleVersion' -Tag 'PMU' {
    It 'reads the runtime module prerelease identity without inferring it from a directory' {
        $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.10'
        $module = Get-Module -ListAvailable "$path/FixtureModule.psd1"
        (Get-ActiveModuleVersion $module).FullVersion | Should -Be '2.0.0-preview.10'
    }
}
