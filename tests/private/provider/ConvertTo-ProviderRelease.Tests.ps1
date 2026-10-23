BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-ProviderRelease' -Tag 'PMU' {
    It 'preserves numeric provider version and license requirement' {
        $resource = [pscustomobject]@{ Name = 'Fixture'; Version = [version]'2.0.0.4'; Prerelease = 'preview.3'; AdditionalMetadata = @{ RequireLicenseAcceptance = 'true' }; Dependencies = @() }
        $release = ConvertTo-ProviderRelease $resource
        $release.Version.FullVersion | Should -Be '2.0.0.4-preview.3'
        $release.RequiresLicenseAcceptance | Should -BeTrue
    }
}
