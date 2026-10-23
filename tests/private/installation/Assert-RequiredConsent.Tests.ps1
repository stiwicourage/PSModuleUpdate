BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RequiredConsent' -Tag 'PMU' {
    Context 'Independent opt-in' {
        It 'does not infer a required opt-in from another kind of consent' {
            { Assert-RequiredConsent $true $false 'PMU.RepositoryTrustRequired' 'Explicit trust required.' } | Should -Throw -ErrorId 'PMU.RepositoryTrustRequired'
        }
    }
}
