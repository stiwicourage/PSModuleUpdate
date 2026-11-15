BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-ProviderLicenseRequirement' -Tag 'PMU', 'PMULicense' {
    Context 'Fail-closed provider license metadata' {
        It 'requires explicit consent when the qualified provider omits license metadata' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{} } | Should -BeTrue
        }
        It 'honors an explicit negative requirement' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' } } | Should -BeFalse
        }
        It 'requires explicit consent when no additional metadata is present' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = $null } | Should -BeTrue
        }
        It 'honors boolean license requirements as given' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = $false } } | Should -BeFalse
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = $true } } | Should -BeTrue
        }
        It 'requires explicit consent when the metadata value is not a string or boolean' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = 0 } } | Should -BeTrue
        }
        It 'treats malformed license metadata as requiring explicit consent' {
            Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ RequireLicenseAcceptance = 'unknown' } } | Should -BeTrue
        }
    }
    It 'requires consent when nonempty metadata has no license key' {
        Get-ProviderLicenseRequirement @{ AdditionalMetadata = @{ Description = 'Fixture' } } | Should -BeTrue
    }
    It 'requires consent for conflicting key spellings even when both values claim no license requirement' {
        $metadata = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
        $metadata.Add('RequireLicenseAcceptance', $false)
        $metadata.Add('requirelicenseacceptance', 'false')
        Get-ProviderLicenseRequirement @{ AdditionalMetadata = $metadata } | Should -BeTrue
        $metadata.Count | Should -Be 2
    }
}
