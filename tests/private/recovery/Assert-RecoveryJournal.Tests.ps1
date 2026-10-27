BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
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
    It 'validates schema before parsing the target version' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.Reinstall = 'false'
        $journal.TargetVersion = 'invalid'
        { Assert-RecoveryJournal $journal $operation } | Should -Throw -ExpectedMessage 'The recovery journal mutation flag is not Boolean.'
    }
    It 'parses the target version before comparing identity' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.TargetVersion = 'invalid'
        $journal.Scope = 'AllUsers'
        { Assert-RecoveryJournal $journal $operation } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
    It 'compares identity case-sensitively before paths and state' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.ModuleName = $journal.ModuleName.ToUpperInvariant()
        $journal.TargetPath = 'unexpected'
        $journal.State = 'invalid'
        { Assert-RecoveryJournal $journal $operation } | Should -Throw -ExpectedMessage 'A required identity or environment precondition changed.'
    }
    It 'validates paths before state' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.TargetPath = 'unexpected'
        $journal.State = 'invalid'
        { Assert-RecoveryJournal $journal $operation } | Should -Throw -ExpectedMessage 'Recovery paths are not the expected PMU-controlled paths.'
    }
}
