BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-InstallationPhase' -Tag 'PMU', 'PMUProgress' {
    Context 'Native progress diagnostics' {
        It 'never puts phase diagnostics on the structured success stream' {
            @(Write-InstallationPhase @{ ModuleName = 'FixtureModule' } 'Staging').Count | Should -Be 0
        }
    }
}
