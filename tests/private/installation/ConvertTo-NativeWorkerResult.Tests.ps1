BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-NativeWorkerResult' -Tag 'PMU', 'PMUNativeHandoff' {
    It 'binds a successful reply to the exact durable journal while withholding credentials' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $result = ConvertTo-NativeWorkerResult $operation $null
        $result.Success | Should -BeTrue
        $result.Token.SHA256 | Should -BeExactly (Get-FileHash $operation.JournalPath).Hash
        $result.PSObject.Properties.Name | Should -Not -Contain 'Credential'
    }
    It 'never gives pre-ownership failures a journal token or raw provider diagnostics' {
        $failure = [Management.Automation.ErrorRecord]::new(
            [InvalidOperationException]::new('fixture-only-sensitive-diagnostic'), 'ProviderFailure', 'InvalidOperation', $null
        )
        $result = ConvertTo-NativeWorkerResult $null $failure
        $result.Success | Should -BeFalse
        $result.Token | Should -BeNullOrEmpty
        $result.ErrorId | Should -BeExactly 'PMU.InstallationFailed'
        $result | ConvertTo-Json | Should -Not -Match 'fixture-only-sensitive-diagnostic'
    }
}
