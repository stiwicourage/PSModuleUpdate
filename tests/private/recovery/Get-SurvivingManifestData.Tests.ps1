BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-SurvivingManifestData' -Tag 'PMU' {
    Context 'Interrupted provider files' {
        It 'returns no identity for a missing manifest rather than executing anything' {
            (Get-SurvivingManifestData "$TestDrive/absent.psd1").Count | Should -Be 0
        }
    }
}
