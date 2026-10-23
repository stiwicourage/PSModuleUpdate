BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Repair-RepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Live owner protection' {
        It 'never attempts cleanup while the recorded owner is alive' {
            Mock Get-RepositoryReceiptEntry { [pscustomobject]@{ Receipt = [pscustomobject]@{ OwnerPid = $PID } } }
            Mock Test-RepositoryReceiptOwnerAlive { $true }
            Mock Clear-OwnedRepositoryReceipt { throw 'Living operation cannot be removed.' }
            Repair-RepositoryReceipt $TestDrive
            Should -Invoke Clear-OwnedRepositoryReceipt -Times 0
        }
    }
}
