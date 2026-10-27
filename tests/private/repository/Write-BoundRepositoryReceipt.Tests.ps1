BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-BoundRepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Atomic bound configuration' {
        It 'replaces the flushed intent with exact API and leaves no temporary binding file' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Write-RepositoryReceipt $receipt $TestDrive
            $receipt.ApiVersion = 'Local'
            Write-BoundRepositoryReceipt ([pscustomobject]@{
                    Receipt = $receipt
                    ReceiptPath = $path
                    Root = $TestDrive
                })
            (Read-RepositoryReceipt $path $TestDrive).ApiVersion | Should -Be Local
            Test-Path "$path.binding" | Should -BeFalse
        }
    }
}
