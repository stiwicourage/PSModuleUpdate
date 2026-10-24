BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-InstalledModuleIdentityList' -Tag 'PMU' {
    It 'reads the manifest prerelease, not the numeric directory name' {
        $null = Initialize-PMUTestPackage $TestDrive '2.0.0-preview.10'
        Mock Resolve-ModuleInstallationRoot { $TestDrive }
        $identity = Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers'
        $identity.FullVersion | Should -Be '2.0.0-preview.10'
        $identity.Scope | Should -Be 'AllUsers'
    }
    It 'rejects a directory whose name differs from the manifest numeric version' {
        $path = Initialize-PMUTestPackage $TestDrive '2.0.0'
        Rename-Item -LiteralPath $path -NewName '9.9.9'
        Mock Resolve-ModuleInstallationRoot { $TestDrive }
        { Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers' } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
}
