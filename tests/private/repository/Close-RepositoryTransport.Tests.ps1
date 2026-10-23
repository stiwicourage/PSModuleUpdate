BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Close-RepositoryTransport' -Tag 'PMUUriBridge' {
    Context 'No ownership for an existing consumer registration' {
        It 'does not acquire a registry lock for a non-temporary lease' {
            Mock Close-OwnedRepositoryTransport { throw 'Consumer registration must not be removed.' }
            Close-RepositoryTransport ([pscustomobject]@{ ReceiptPath = $null }) $null
            Should -Invoke Close-OwnedRepositoryTransport -Times 0
        }
    }
}
