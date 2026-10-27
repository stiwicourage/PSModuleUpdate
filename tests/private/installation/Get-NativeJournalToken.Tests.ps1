BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeJournalToken' -Tag 'PMUNative' {
    It 'binds exact bytes and phase to the private transaction instance' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $token = Get-NativeJournalToken $operation
        $token.TransactionId | Should -BeExactly $operation.Journal.TransactionId
        $token.SHA256 | Should -BeExactly (Get-FileHash $operation.JournalPath).Hash
        $token.State | Should -BeExactly 'ReplacementInProgress'
    }
}
