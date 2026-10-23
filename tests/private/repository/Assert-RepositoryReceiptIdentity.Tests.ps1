BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RepositoryReceiptIdentity' -Tag 'PMUUriBridge' {
    Context 'Operation identity consistency' {
        It 'rejects a name not derived from its operation nonce' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $receipt.RegistrationName = "pmu-uri-$([guid]::NewGuid().ToString('N'))"
            { Assert-RepositoryReceiptIdentity $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
        }
    }
}
