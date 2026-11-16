BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RepositoryReceiptIdentity' -Tag 'PMUUriBridge' {
    Context 'Operation identity consistency' {
        It 'rejects a name not derived from its operation nonce' {
            $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
            $receipt.RegistrationName = "pmu-uri-$([guid]::NewGuid().ToString('N'))"
            { Assert-RepositoryReceiptIdentity $receipt } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
        }
    }
    It 'rejects an otherwise valid receipt with invalid <Field>' -ForEach @(
        @{ Field = 'SchemaVersion'; Value = 2 }
        @{ Field = 'OperationId'; Value = 'ABCDEF0123456789ABCDEF0123456789' }
        @{ Field = 'OwnerPid'; Value = '01234' }
        @{ Field = 'OwnerStartedUtcTicks'; Value = '12345678901234567' }
        @{ Field = 'UriHash'; Value = ('a' * 64) }
        @{ Field = 'ApiVersion'; Value = 'v3' }
    ) {
        $receipt = ConvertTo-RepositoryReceipt (Initialize-PMUUriFixture $TestDrive).Source
        if ($Field -eq 'OperationId') {
            $receipt.RegistrationName = "pmu-uri-$Value"
        }
        $receipt.$Field = $Value
        { Assert-RepositoryReceiptIdentity $receipt } |
            Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired' -ExpectedMessage 'Repository receipt identity is invalid.'
    }
}
