BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-InstallationProgress' -Tag 'PMU', 'PMUProgress' {
    Context 'Native progress records' {
        BeforeEach {
            Mock Write-Progress {}
        }
        It 'emits native status for an interactive update without structured success output' {
            @(Write-InstallationProgress @{ ModuleName = 'FixtureModule' } 'Staging').Count | Should -Be 0
            Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter {
                $Id -eq 17330 -and $Activity -ceq 'Updating FixtureModule' -and
                $Status -ceq 'Staging' -and -not $Completed
            }
        }
        It 'completes the same native activity rather than emitting another status update' {
            @(Write-InstallationProgress @{ ModuleName = 'FixtureModule' } 'Completed').Count | Should -Be 0
            Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter {
                $Id -eq 17330 -and $Activity -ceq 'Updating FixtureModule' -and $Completed
            }
        }
    }
}
