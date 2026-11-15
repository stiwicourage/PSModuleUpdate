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
    It 'refuses a self-consistent receipt owned by a different process and releases the registry lock' {
        Mock Resolve-RepositoryTransportRoot { $TestDrive }
        $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
        $receipt.OwnerPid = [int]::MaxValue
        $path = Write-RepositoryReceipt $receipt $TestDrive
        $lease = [pscustomobject]@{ ReceiptPath = $path; Receipt = $receipt }
        { Close-OwnedRepositoryTransport $lease } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired' -ExpectedMessage 'A different operation owns this registration.'
        Test-Path -LiteralPath $path | Should -BeTrue
        $lock = Enter-RepositoryRegistryLock $TestDrive 50
        try {
            $lock.CanWrite | Should -BeTrue
        } finally {
            $lock.Dispose()
        }
    }
}
