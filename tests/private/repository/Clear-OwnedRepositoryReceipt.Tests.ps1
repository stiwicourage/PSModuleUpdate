BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Clear-OwnedRepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Absent registration after a partial create' {
        It 'removes only the validated receipt when no registration was created' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $path = Write-RepositoryReceipt $receipt $TestDrive
            Mock Get-RepositoryRegistration { }
            Clear-OwnedRepositoryReceipt ([pscustomobject]@{ Path = $path; Receipt = $receipt })
            Test-Path $path | Should -BeFalse
        }
    }
}
