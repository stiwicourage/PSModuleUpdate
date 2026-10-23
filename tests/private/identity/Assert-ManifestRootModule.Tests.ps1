BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-ManifestRootModule' -Tag 'PMU' {
    It 'rejects a declared module path outside its own package' {
        { Assert-ManifestRootModule @{ RootModule = '../escape.psm1' } "$TestDrive/module.psd1" } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
    }
}
