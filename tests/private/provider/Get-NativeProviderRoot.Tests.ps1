BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeProviderRoot' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'derives a unique owned sibling of staging from the actual journal nonce' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Get-NativeProviderRoot $operation | Should -BeExactly (
            Join-Path $operation.WorkRoot "native-$($operation.Journal.TransactionId)"
        )
    }
    It 'refuses to invent a native provider nonce when the journal is <State>' -ForEach @(
        @{ State = 'absent'; Journal = $null }
        @{ State = 'legacy'; Journal = [pscustomobject]@{ State = 'Completed' } }
    ) {
        $root = Join-Path $TestDrive "missing-nonce-$State"
        $operation = [pscustomobject]@{ WorkRoot = $root; Journal = $Journal }
        { Get-NativeProviderRoot $operation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
        Test-Path -LiteralPath $root | Should -BeFalse
    }
}
