BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-MatchingProperty' -Tag 'PMU' {
    It 'compares required fields without leaking differing values into errors' {
        { Assert-MatchingProperty @{ Uri = 'secret-fixture' } @{ Uri = 'expected' } @('Uri') 'PMU.RepositoryChanged' } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }
}
