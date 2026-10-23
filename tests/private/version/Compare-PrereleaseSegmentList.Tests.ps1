BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Compare-PrereleaseSegmentList' -Tag 'PMU' {
    Context 'Semantic identifier sequence' {
        It 'orders an otherwise equal longer sequence after its prefix' {
            Compare-PrereleaseSegmentList @('alpha', '1') @('alpha') | Should -Be 1
        }
    }
}
