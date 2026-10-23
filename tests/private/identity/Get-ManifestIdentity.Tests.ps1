BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
    . "$root/tests/TestHelpers/Initialize-PMUTestPackage.ps1"
}
Describe 'Get-ManifestIdentity' -Tag 'PMU' {
    It 'reads a stable manifest without executing its throwing root module' {
        $path = Initialize-PMUTestPackage $TestDrive '1.2.3'
        (Get-ManifestIdentity "$path/FixtureModule.psd1").Version.FullVersion | Should -Be '1.2.3'
    }
    It 'rejects a missing declared root module as incomplete extraction' {
        $path = Initialize-PMUTestPackage $TestDrive '1.2.3-preview.1'
        Remove-Item "$path/FixtureModule.psm1"
        { Get-ManifestIdentity "$path/FixtureModule.psd1" } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
    }
}
