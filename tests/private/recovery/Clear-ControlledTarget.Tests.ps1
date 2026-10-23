BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Clear-ControlledTarget' -Tag 'PMU' {
    It 'refuses to remove any other numeric directory' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.TargetPath = Split-Path -Parent $journal.TargetPath
        { Clear-ControlledTarget $journal } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
        Test-Path $operation.Plan.TargetInstalledPath | Should -BeTrue
    }
    It 'refuses to delete an unexpected valid GUID even inside a journal numeric directory' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $null = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '2.0.0-preview.1' ([guid]::NewGuid())
        { Clear-ControlledTarget $operation.Journal } | Should -Throw -ErrorId 'PMU.GuidMismatch'
        Test-Path $operation.Plan.TargetInstalledPath | Should -BeTrue
    }
}
