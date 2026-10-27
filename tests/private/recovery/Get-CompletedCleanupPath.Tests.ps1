BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-CompletedCleanupPath' -Tag 'PMU', 'PMUNativeHandoff' {
    It 'does not infer or remove native stores for a legacy journal with no nonce' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $operation.Journal.PSObject.Properties.Remove('TransactionId')
        @(Get-CompletedCleanupPath $operation $operation.Journal) | Should -Be @($operation.StageRoot, $operation.BackupPath)
    }
}
