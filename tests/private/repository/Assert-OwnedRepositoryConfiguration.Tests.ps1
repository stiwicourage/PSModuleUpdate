BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-OwnedRepositoryConfiguration' -Tag 'PMUUriBridge' {
    Context 'No repointed-name deletion' {
        It 'fails closed for a crashed unbound intent instead of accepting an inferred API' {
            $source = (Initialize-PMUUriFixture $TestDrive).Source
            $receipt = ConvertTo-RepositoryReceipt $source
            $entry = [pscustomobject]@{ Name = $receipt.RegistrationName; Uri = $source.Uri; ApiVersion = 'V3'; Trusted = $false; Priority = 50 }
            { Assert-OwnedRepositoryConfiguration $entry $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
        }
        It 'rejects a trusted-state change even with the same nonce and URI hash' {
            $source = (Initialize-PMUUriFixture $TestDrive).Source
            $receipt = ConvertTo-RepositoryReceipt $source
            $entry = [pscustomobject]@{ Name = $receipt.RegistrationName; Uri = $source.Uri; ApiVersion = 'Unknown'; Trusted = $true; Priority = 50 }
            { Assert-OwnedRepositoryConfiguration $entry $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
        }
    }
}
