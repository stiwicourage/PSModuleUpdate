BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-RepositoryReceipt' -Tag 'PMUUriBridge' {
    Context 'Ownership intent before registration' {
        It 'contains process identity and an endpoint hash but no raw URL or credential' {
            $fixture = Initialize-PMUUriFixture $TestDrive
            $receipt = ConvertTo-RepositoryReceipt $fixture.Source
            $receipt.OwnerPid | Should -Be $PID
            $receipt.RegistrationName | Should -Be "pmu-uri-$($receipt.OperationId)"
            $receipt.UriHash | Should -Match '^[A-F0-9]{64}$'
            ConvertTo-Json $receipt | Should -Not -Match 'https:|transport.invalid|Credential'
        }
    }
}
