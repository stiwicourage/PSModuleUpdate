BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RepositoryName' -Tag 'PMU' {
    Context 'Literal repository binding' {
        It 'rejects wildcard and blank repository names' {
            { Assert-RepositoryName '*' } | Should -Throw -ErrorId 'PMU.InvalidRequest'
            { Assert-RepositoryName ' ' } | Should -Throw -ErrorId 'PMU.InvalidRequest'
        }
    }
}
