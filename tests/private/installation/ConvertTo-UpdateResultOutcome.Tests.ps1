BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-UpdateResultOutcome' -Tag 'PMU' {
    It 'reports verified installation facts and restart policy in outcome order' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $installed = @{
            Version = '2.0.0-preview.2'
            Path = 'verified-path'
        }
        Mock Test-RestartRequired { $true }
        $outcome = ConvertTo-UpdateResultOutcome $operation.Plan $installed 'Installed' 'Verified'
        @($outcome.Keys) | Should -Be 'InstalledVersion TargetVersion InstalledPath VerificationStatus RestartRequired DependencySummary RecoveryStatus RecoveryGuidance'.Split(' ')
        $outcome.InstalledVersion | Should -BeExactly $installed.Version
        $outcome.InstalledPath | Should -BeExactly $installed.Path
        $outcome.RestartRequired | Should -BeTrue
        Should -Invoke Test-RestartRequired -Times 1 -Exactly -ParameterFilter { $Outcome -eq 'Installed' }
    }
    It 'copies dependency containers but not items and excludes private installation context' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $dependency = [pscustomobject]@{ Name = 'Dependency' }
        $operation.Plan.DependencySummary = @($dependency)
        $installed = @{
            Version = $null
            Path = $null
            Credential = 'secret'
            Parent = 'private'
            Context = 'private'
        }
        Mock Test-RestartRequired { $false }
        $outcome = ConvertTo-UpdateResultOutcome $operation.Plan $installed 'WhatIf' 'NotPerformed'
        [object]::ReferenceEquals($outcome.DependencySummary, $operation.Plan.DependencySummary) | Should -BeFalse
        [object]::ReferenceEquals($outcome.DependencySummary[0], $dependency) | Should -BeTrue
        ($outcome | ConvertTo-Json -Depth 8) | Should -Not -Match 'Credential|Parent|Context|secret|private'
    }
}
