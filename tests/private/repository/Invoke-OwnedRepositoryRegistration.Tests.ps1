BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-OwnedRepositoryRegistration' -Tag 'PMUUriBridge' {
    Context 'Receipt must precede provider mutation' {
        It 'never cleans a pre-existing registration after a random-name collision' {
            Mock Get-RepositoryRegistration { [pscustomobject]@{ Name = 'ExistingEntry' } }
            Mock Clear-OwnedRepositoryReceipt {}
            $source = (Initialize-PMUUriFixture $TestDrive).Source
            { Invoke-OwnedRepositoryRegistration $source $TestDrive } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable*'
            Should -Invoke Clear-OwnedRepositoryReceipt -Times 0
        }
        It 'never invokes registration when durable receipt creation fails' {
            Mock Write-RepositoryReceipt { throw [UnauthorizedAccessException]::new('isolated receipt permission failure') }
            Mock Register-OwnedRepository { throw 'No registration is permitted.' }
            { Invoke-OwnedRepositoryRegistration (Initialize-PMUUriFixture $TestDrive).Source $TestDrive } | Should -Throw
            Should -Invoke Register-OwnedRepository -Times 0
        }
    }
}
