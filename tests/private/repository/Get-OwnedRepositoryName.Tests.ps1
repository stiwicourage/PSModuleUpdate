BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-OwnedRepositoryName' -Tag 'PMUUriBridge' {
    Context 'Receipt-backed temporary source exclusion' {
        It 'does not exclude a registration merely because its name resembles a PMU nonce' {
            Mock Resolve-RepositoryTransportRoot { $TestDrive }
            Mock Get-RepositoryReceiptEntry { }
            @(Get-OwnedRepositoryName).Count | Should -Be 0
        }
        Context 'Validated receipt ownership' {
            BeforeEach {
                $script:ownedSource = (Initialize-PMUUriFixture $TestDrive).Source
                $script:ownedReceipt = ConvertTo-RepositoryReceipt $ownedSource
                $script:ownedRegistration = [pscustomobject]@{
                    Name = $ownedReceipt.RegistrationName
                    Uri = $ownedSource.Uri
                    ApiVersion = $ownedReceipt.ApiVersion
                    Trusted = $false
                    Priority = 50
                }
                Mock Resolve-RepositoryTransportRoot { $TestDrive }
                Mock Get-RepositoryReceiptEntry { [pscustomobject]@{ Receipt = $ownedReceipt } }
                Mock Get-RepositoryRegistration { $ownedRegistration }
            }
            It 'returns only the name whose registration matches the durable ownership identity' {
                @(Get-OwnedRepositoryName) | Should -Be @($ownedReceipt.RegistrationName)
            }
            It 'ignores a receipt whose registration no longer exists' {
                Mock Get-RepositoryRegistration {}
                @(Get-OwnedRepositoryName).Count | Should -Be 0
            }
            It 'rejects a reused name with a changed repository endpoint' {
                $ownedRegistration.Uri = 'https://other.invalid/v3/index.json'
                { Get-OwnedRepositoryName } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired'
            }
        }
    }
}
