BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-RepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Durable create-only intent' {
        It 'writes complete readable JSON and refuses to overwrite an existing operation' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Write-RepositoryReceipt $receipt $TestDrive
            (Read-RepositoryReceipt $path $TestDrive).OperationId | Should -Be $receipt.OperationId
            { Write-RepositoryReceipt $receipt $TestDrive } | Should -Throw
        }
    }
}
