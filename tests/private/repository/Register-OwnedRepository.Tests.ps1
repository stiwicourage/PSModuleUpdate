BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Register-OwnedRepository' -Tag 'PMUUriBridge' {
    Context 'No overwrite on nonce collision' {
        It 'does not attempt registration when the generated name already exists' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Write-RepositoryReceipt $receipt $TestDrive
            Mock Get-RepositoryRegistration { [pscustomobject]@{ Name = 'ExistingEntry' } }
            $lease = [pscustomobject]@{ Name = $receipt.RegistrationName; ReceiptPath = $path }
            { Register-OwnedRepository $lease } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable*'
            Test-Path $path | Should -BeFalse
        }
    }
}
