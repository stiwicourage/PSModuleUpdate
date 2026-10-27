BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Close-OwnedRepositoryTransport' -Tag 'PMUUriBridge' {
    Context 'Operation nonce validation under the registry lock' {
        It 'does not release another operation receipt' {
            Mock Resolve-RepositoryTransportRoot { $TestDrive }
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Write-RepositoryReceipt $receipt $TestDrive
            $foreign = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $lease = [pscustomobject]@{
                ReceiptPath = $path
                Receipt = $foreign
            }
            { Close-OwnedRepositoryTransport $lease } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
            Test-Path $path | Should -BeTrue
        }
    }
}
