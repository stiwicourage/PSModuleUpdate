BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeProviderRoot' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'derives a unique owned sibling of staging from the actual journal nonce' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Get-NativeProviderRoot $operation | Should -BeExactly (
            Join-Path $operation.WorkRoot "native-$($operation.Journal.TransactionId)"
        )
    }
}
