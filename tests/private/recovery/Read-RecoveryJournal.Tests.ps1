BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Read-RecoveryJournal' -Tag 'PMU' {
    It 'fails closed on corrupt persisted JSON' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Initialize-ControlledDirectory $operation.WorkRoot
        [IO.File]::WriteAllText($operation.JournalPath, '{partial')
        { Read-RecoveryJournal $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
