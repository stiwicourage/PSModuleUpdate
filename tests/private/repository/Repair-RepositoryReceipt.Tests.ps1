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
        It 'removes an abandoned durable receipt only after confirming its owner and registration are absent' {
            Initialize-ControlledDirectory $TestDrive
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Write-RepositoryReceipt $receipt $TestDrive
            Mock Get-RepositoryProcessStart { $null }
            Mock Get-RepositoryRegistration {}
            Repair-RepositoryReceipt $TestDrive
            Test-Path -LiteralPath $path | Should -BeFalse
            Test-Path -LiteralPath $TestDrive -PathType Container | Should -BeTrue
            Should -Invoke Get-RepositoryRegistration -Times 1 -Exactly -ParameterFilter {
                $Name -ceq $receipt.RegistrationName
            }
        }
    }
}
