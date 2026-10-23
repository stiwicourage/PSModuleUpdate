BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-InstalledModuleIdentityList' -Tag 'PMU' {
    It 'reads the manifest prerelease, not the numeric directory name' {
        $null = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.10'
        Mock Resolve-ModuleInstallationRoot { $TestDrive }
        $identity = Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers'
        $identity.FullVersion | Should -Be '2.0.0-preview.10'
        $identity.Scope | Should -Be 'AllUsers'
    }
}
