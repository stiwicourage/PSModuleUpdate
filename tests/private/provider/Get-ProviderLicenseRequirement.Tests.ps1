BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ProviderLicenseRequirement' -Tag 'PMU', 'PMULicense' {
    Context 'Fail-closed provider license metadata' {
        It 'requires explicit consent when the qualified provider omits license metadata' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{} } | Should -BeTrue
        }
        It 'honors an explicit negative requirement' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' } } | Should -BeFalse
        }
        It 'treats malformed license metadata as requiring explicit consent' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = 'unknown' } } | Should -BeTrue
        }
    }
}
