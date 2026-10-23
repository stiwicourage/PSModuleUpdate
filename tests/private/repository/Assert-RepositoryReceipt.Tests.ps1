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
}
