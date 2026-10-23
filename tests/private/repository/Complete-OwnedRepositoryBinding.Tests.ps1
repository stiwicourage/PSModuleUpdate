BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Complete-OwnedRepositoryBinding' -Tag 'PMUUriBridge' {
    Context 'Provider-observed identity only' {
        It 'rejects an unresolved native API without rewriting ownership intent' {
            $source = (Initialize-PMUUriFixture $TestDrive).Source
            $receipt = ConvertTo-RepositoryReceipt $source
            $lease = [pscustomobject]@{ Receipt = $receipt }
            Mock Write-BoundRepositoryReceipt {}
            { Complete-OwnedRepositoryBinding $lease ([pscustomobject]@{ ApiVersion = 'Unknown' }) } |
                Should -Throw -ErrorId 'PMU.RepositoryUnavailable*'
            Should -Invoke Write-BoundRepositoryReceipt -Times 0
        }
    }
}
