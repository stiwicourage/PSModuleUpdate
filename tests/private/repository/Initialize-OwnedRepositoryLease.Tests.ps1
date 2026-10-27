BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Initialize-OwnedRepositoryLease' -Tag 'PMUUriBridge' {
    It 'persists the receipt before returning the original source and receipt references' {
        $source = [pscustomobject]@{ Name = 'source' }
        $expectedReceipt = [pscustomobject]@{ RegistrationName = 'owned' }
        Mock ConvertTo-RepositoryReceipt { $expectedReceipt }
        Mock Write-RepositoryReceipt { 'receipt-path' }
        $lease = Initialize-OwnedRepositoryLease $source $TestDrive

        $lease.PSObject.Properties.Name | Should -Be @('Name', 'ReceiptPath', 'Root', 'Receipt', 'Source')
        $lease.Name | Should -Be 'owned'
        $lease.ReceiptPath | Should -Be 'receipt-path'
        $lease.Root | Should -Be $TestDrive
        [object]::ReferenceEquals($lease.Receipt, $expectedReceipt) | Should -BeTrue
        [object]::ReferenceEquals($lease.Source, $source) | Should -BeTrue
        Should -Invoke Write-RepositoryReceipt -Times 1 -ParameterFilter {
            [object]::ReferenceEquals($Receipt, $expectedReceipt) -and $Root -eq $TestDrive
        }
    }

    It 'propagates durable receipt failure without returning a lease' {
        Mock ConvertTo-RepositoryReceipt { [pscustomobject]@{ RegistrationName = 'owned' } }
        Mock Write-RepositoryReceipt { throw [UnauthorizedAccessException]::new('receipt denied') }
        { Initialize-OwnedRepositoryLease ([pscustomobject]@{}) $TestDrive } |
            Should -Throw '*receipt denied*'
    }
}
