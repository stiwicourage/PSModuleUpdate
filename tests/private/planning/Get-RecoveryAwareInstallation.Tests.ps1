BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-RecoveryAwareInstallation' -Tag 'PMU' {
    Context 'Selected-scope resolution' {
        It 'uses current manifests when no unfinished journal exists' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $script:selectedRoot = $operation.Plan.DestinationRoot
            Mock Resolve-ModuleInstallationRoot {
                $script:selectedRoot
            }
            $state = Get-RecoveryAwareInstallation 'FixtureModule' 'CurrentUser' $operation.Plan.ModuleGuid
            $state.FromBackup | Should -BeFalse
            $state.Selected[0].FullVersion | Should -Be '2.0.0-preview.1'
        }
    }

    It 'preserves recovery-first ordering and excludes only the journal target' {
        $script:journal = [pscustomobject]@{
            TargetPath = Join-Path $TestDrive 'Modules/FixtureModule/2.0.0'
        }
        $script:prior = [pscustomobject]@{
            FullVersion = '2.0.0-preview.1'
        }
        $script:sideBySide = [pscustomobject]@{
            FullVersion = '2.0.0-preview.1'
        }
        Mock Get-PlanningRecoveryJournal {
            $script:journal
        }
        Mock Get-RecoveryInstallationObservation {
            $script:prior
        }
        Mock Get-InstalledModuleIdentityList {
            $script:sideBySide
        }
        Mock Assert-SelectedInstallation {}

        $state = Get-RecoveryAwareInstallation 'FixtureModule' 'CurrentUser' ([guid]::Empty)

        @($state.PSObject.Properties.Name) | Should -Be @('Selected', 'Journal', 'FromBackup')
        $state.FromBackup | Should -BeTrue
        [object]::ReferenceEquals($state.Journal, $journal) | Should -BeTrue
        $state.Selected.Count | Should -Be 2
        [object]::ReferenceEquals($state.Selected[0], $prior) | Should -BeTrue
        [object]::ReferenceEquals($state.Selected[1], $sideBySide) | Should -BeTrue
        Should -Invoke Get-InstalledModuleIdentityList -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'FixtureModule' -and $Scope -ceq 'CurrentUser' -and
            $ExcludedPath -ceq $journal.TargetPath
        }
    }
}
