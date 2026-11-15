BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Closed nonsecret schema' {
        It 'accepts a valid receipt and rejects added consumer URL storage' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            { Assert-RepositoryReceipt $receipt } | Should -Not -Throw
            $receipt | Add-Member -NotePropertyName Uri -NotePropertyValue 'https://unwanted.invalid'
            { Assert-RepositoryReceipt $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
        }
    }
    It 'rejects a missing required receipt field <Field> before identity validation' -ForEach @(
        @{ Field = 'ApiVersion' }
        @{ Field = 'OwnerPid' }
        @{ Field = 'UriHash' }
    ) {
        $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
        $receipt.PSObject.Properties.Remove($Field)
        { Assert-RepositoryReceipt $receipt } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired' -ExpectedMessage 'Repository receipt schema is invalid.'
    }
    It 'rejects altered ownership policy <Field> without changing the receipt' -ForEach @(
        @{ Field = 'Trusted'; Value = $true }
        @{ Field = 'Priority'; Value = 1 }
    ) {
        $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
        $receipt.$Field = $Value
        $before = ConvertTo-Json $receipt -Compress
        { Assert-RepositoryReceipt $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'
        ConvertTo-Json $receipt -Compress | Should -BeExactly $before
    }
}
