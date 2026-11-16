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
        It 'removes the temporary binding after replacement fails without deleting the destination' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Join-Path $TestDrive "$($receipt.OperationId).json"
            $null = New-Item -ItemType Directory -Path $path
            $sentinel = Join-Path $path 'retain.txt'
            [IO.File]::WriteAllText($sentinel, 'retained destination')
            $lease = [pscustomobject]@{ Receipt = $receipt; ReceiptPath = $path; Root = $TestDrive }
            { Write-BoundRepositoryReceipt $lease } | Should -Throw
            Test-Path -LiteralPath "$path.binding" | Should -BeFalse
            Get-Content -LiteralPath $sentinel -Raw | Should -BeExactly 'retained destination'
        }
    }
}
