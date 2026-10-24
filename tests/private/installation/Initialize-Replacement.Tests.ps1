BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Initialize-Replacement' -Tag 'PMU' {
    It 'does not use Reinstall or create a backup for a different numeric target' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetInstalledPath = Join-Path $operation.Plan.DestinationRoot 'FixtureModule/3.0.0'
        Initialize-ControlledDirectory $operation.WorkRoot
        Initialize-Replacement $operation @()
        $operation.Reinstall | Should -BeFalse
        Test-Path $operation.BackupPath | Should -BeFalse
        $operation.Journal.State | Should -Be 'Preparation'
    }
    It 'refuses to replace an installed target that has a different GUID' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $null = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '2.0.0-preview.2' ([guid]::NewGuid())
        { Initialize-Replacement $operation @() } | Should -Throw -ErrorId 'PMU.GuidMismatch'
    }
}
