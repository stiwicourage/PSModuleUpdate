BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-RecoveryTargetComplete' -Tag 'PMU' {
    It 'rejects a valid target manifest whose complete tree differs' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $null = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '2.0.0-preview.2'
        [IO.File]::WriteAllText("$($operation.Plan.TargetInstalledPath)/extra.txt", 'unexpected')
        Test-RecoveryTargetComplete $operation.Journal | Should -BeFalse
    }
}
