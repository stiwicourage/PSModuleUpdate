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
    It 'rejects a manifest that does not declare both version and GUID' {
        Set-Content -LiteralPath "$TestDrive/NoGuid.psd1" -Value "@{ ModuleVersion = '1.0.0' }"
        { Get-ManifestIdentity "$TestDrive/NoGuid.psd1" } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
    }
    It 'rejects a rejected manifest that cannot be safely read' {
        Set-Content -LiteralPath "$TestDrive/Broken.psd1" -Value '@{ ModuleVersion = (Get-Date) }'
        { Get-ManifestIdentity "$TestDrive/Broken.psd1" } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
    }
    It 'rejects a missing declared root module as incomplete extraction' {
        $path = Initialize-PMUTestPackage $TestDrive '1.2.3-preview.1'
        Remove-Item "$path/FixtureModule.psm1"
        { Get-ManifestIdentity "$path/FixtureModule.psd1" } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
    }
}
