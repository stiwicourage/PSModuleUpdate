BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-PolicyValue' -Tag 'PMU' {
    It 'rejects enum casing and non-string range values' {
        { Assert-PolicyValue 'Channel' 'stable' ([string]) @('Stable') } | Should -Throw -ErrorId 'PMU.InvalidRequest'
        { Assert-PolicyValue 'VersionRange' 5 ([string]) } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
}
