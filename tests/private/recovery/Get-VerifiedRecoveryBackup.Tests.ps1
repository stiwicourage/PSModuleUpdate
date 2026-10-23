BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-VerifiedRecoveryBackup' -Tag 'PMU' {
    Context 'Verified previous identity' {
        It 'returns the previous manifest only after tree verification' {
            $operation = Initialize-PMURecoveryFixture $TestDrive
            (Get-VerifiedRecoveryBackup $operation.Journal).Version.FullVersion | Should -Be '2.0.0-preview.1'
        }
    }
}
