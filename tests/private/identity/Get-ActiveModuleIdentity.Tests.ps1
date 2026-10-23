BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ActiveModuleIdentity' -Tag 'PMU' {
    It 'does not report a ListAvailable reference as actually loaded' {
        $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1'
        $module = Get-Module -ListAvailable "$path/FixtureModule.psd1"
        Get-ActiveModuleIdentity $module | Should -BeNullOrEmpty
    }
    It 'retains the active prerelease identity after the same numeric directory changes on disk' {
        $path = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.1'
        $module = Get-Module -ListAvailable "$path/FixtureModule.psd1"
        $script:loadedReference = $module
        Mock Get-Module { $script:loadedReference }
        $null = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.2'
        (Get-ActiveModuleIdentity $module).Version.FullVersion | Should -Be '2.0.0-preview.1'
    }
}
