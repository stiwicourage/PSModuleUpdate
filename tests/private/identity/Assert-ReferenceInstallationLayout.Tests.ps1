BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-ReferenceInstallationLayout' -Tag 'PMU', 'PMUSafety' {
    Context 'Provider-managed reference layout' {
        It 'accepts exactly one matching scope manifest' {
            $active = @{ ManifestPath = "$TestDrive/Modules/FixtureModule/1.0.0/FixtureModule.psd1" }
            { Assert-ReferenceInstallationLayout $active @($active) $null } | Should -Not -Throw
        }
        It 'rejects a source checkout unrelated to the observed provider installations' {
            $active = @{ ManifestPath = "$TestDrive/source/FixtureModule.psd1" }
            { Assert-ReferenceInstallationLayout $active @() $null } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
        }
        It 'rejects ambiguous matching observations' {
            $active = @{ ManifestPath = "$TestDrive/FixtureModule.psd1" }
            { Assert-ReferenceInstallationLayout $active @($active, $active) $null } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
        }
    }
}
