BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-ProviderRelease' -Tag 'PMU' {
    It 'preserves numeric provider version and license requirement' {
        $resource = [pscustomobject]@{
            Name = 'Fixture'
            Version = [version]'2.0.0.4'
            Prerelease = 'preview.3'
            AdditionalMetadata = @{ RequireLicenseAcceptance = 'true' }
            Dependencies = @()
        }
        $release = ConvertTo-ProviderRelease $resource
        $release.Version.FullVersion | Should -Be '2.0.0.4-preview.3'
        $release.RequiresLicenseAcceptance | Should -BeTrue
    }
    It 'projects stable release identity and dependency names without provider objects leaking through' {
        $resource = [pscustomobject]@{
            Name = 'Fixture'
            Version = [version]'2.1.0'
            Prerelease = ''
            AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' }
            Dependencies = @([pscustomobject]@{ Name = 'First' }, [pscustomobject]@{ Name = 'Second' })
        }
        $release = ConvertTo-ProviderRelease $resource
        $release.Name | Should -BeExactly 'Fixture'
        $release.Version.FullVersion | Should -BeExactly '2.1.0'
        $release.RequiresLicenseAcceptance | Should -BeFalse
        $release.Dependencies | Should -Be @('First', 'Second')
    }
}
