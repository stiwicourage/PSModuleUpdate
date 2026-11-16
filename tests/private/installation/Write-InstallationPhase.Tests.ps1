BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-InstallationPhase' -Tag 'PMU', 'PMUProgress' {
    Context 'Native progress diagnostics' {
        It 'never puts phase diagnostics on the structured success stream' {
            @(Write-InstallationPhase @{ ModuleName = 'FixtureModule' } 'Staging').Count | Should -Be 0
        }
    }
    Context 'Host policy' {
        BeforeEach {
            Mock Write-InstallationProgress {}
        }
        It 'suppresses progress for a <HostKind> host' -ForEach @(
            @{ HostKind = 'redirected'; OutputRedirected = $true; NonInteractive = $false }
            @{ HostKind = 'noninteractive'; OutputRedirected = $false; NonInteractive = $true }
        ) {
            Mock Get-InstallationProgressHost { @{ OutputRedirected = $OutputRedirected; NonInteractive = $NonInteractive } }
            @(Write-InstallationPhase @{ ModuleName = 'FixtureModule' } 'Staging').Count | Should -Be 0
            Should -Invoke Write-InstallationProgress -Times 0 -Exactly
        }
        It 'forwards the original plan and phase only when the host permits native progress' {
            $expectedPlan = [pscustomobject]@{ ModuleName = 'FixtureModule' }
            Mock Get-InstallationProgressHost { @{ OutputRedirected = $false; NonInteractive = $false } }
            @(Write-InstallationPhase $expectedPlan 'Staging').Count | Should -Be 0
            Should -Invoke Write-InstallationProgress -Times 1 -Exactly -ParameterFilter {
                [object]::ReferenceEquals($Plan, $expectedPlan) -and $Phase -ceq 'Staging'
            }
        }
    }
}
