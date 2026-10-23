BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryJournal' -Tag 'PMU' {
    It 'rejects a wrong-scope journal even when all filesystem paths exist' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.Scope = 'AllUsers'
        { Assert-RecoveryJournal $journal $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
    It 'rejects untyped destructive flags in untrusted JSON' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.Reinstall = 'false'
        { Assert-RecoveryJournal $journal $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
