BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RecoveryAwareInstallation' -Tag 'PMU' {
    Context 'Selected-scope resolution' {
        It 'uses current manifests when no unfinished journal exists' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $script:selectedRoot = $operation.Plan.DestinationRoot
            Mock Resolve-ModuleInstallationRoot { $script:selectedRoot }
            $state = Get-RecoveryAwareInstallation 'FixtureModule' 'CurrentUser' $operation.Plan.ModuleGuid
            $state.FromBackup | Should -BeFalse
            $state.Selected[0].FullVersion | Should -Be '2.0.0-preview.1'
        }
    }
}
