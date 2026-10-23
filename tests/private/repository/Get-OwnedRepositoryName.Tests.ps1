BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-OwnedRepositoryName' -Tag 'PMUUriBridge' {
    Context 'Receipt-backed temporary source exclusion' {
        It 'does not exclude a registration merely because its name resembles a PMU nonce' {
            Mock Resolve-RepositoryTransportRoot { $TestDrive }
            Mock Get-RepositoryReceiptEntry { }
            @(Get-OwnedRepositoryName).Count | Should -Be 0
        }
    }
}
