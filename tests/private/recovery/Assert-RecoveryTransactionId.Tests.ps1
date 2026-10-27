BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryTransactionId' -Tag 'PMUNative' {
    It 'rejects malformed or nonstring transaction identities' -ForEach @(
        @{ Value = 42 }
        @{ Value = $null }
        @{ Value = 'invalid' }
    ) {
        { Assert-RecoveryTransactionId $Value } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
