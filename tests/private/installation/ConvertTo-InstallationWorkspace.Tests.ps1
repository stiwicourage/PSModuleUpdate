BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'ConvertTo-InstallationWorkspace' -Tag 'PMU' {
    BeforeEach {
        $plan = [pscustomobject]@{
            ModuleName = 'FixtureModule'
            TargetNumericVersion = '2.0.0'
        }
        $dataRoot = Join-Path $TestDrive 'data'
        $workRoot = Join-Path $dataRoot 'fixture-lock'
        $script:workspace = ConvertTo-InstallationWorkspace $plan $dataRoot $workRoot
    }

    It 'projects prepared paths in lifecycle order without creating the workspace' {
        $workspace.GetType() | Should -Be ([Collections.Specialized.OrderedDictionary])
        $expectedNames = @(
            'DataRoot', 'WorkRoot', 'LockPath', 'JournalPath', 'StageRoot', 'BackupPath'
            'Reinstall', 'Journal', 'Lock', 'StagedPath', 'RecoveryStatus', 'RequiresLicenseAcceptance'
        )
        ($workspace.Keys -join ',') | Should -BeExactly ($expectedNames -join ',')
        $workspace.DataRoot | Should -BeExactly $dataRoot
        $workspace.WorkRoot | Should -BeExactly $workRoot
        $workspace.LockPath | Should -BeExactly (Join-Path $workRoot 'operation.lock')
        $workspace.JournalPath | Should -BeExactly (Join-Path $workRoot 'journal.json')
        $workspace.StageRoot | Should -BeExactly (Join-Path $workRoot 'stage')
        $workspace.BackupPath | Should -BeExactly (Join-Path $workRoot 'backup')
        $workspace.StagedPath | Should -BeExactly (Join-Path $workRoot 'stage/FixtureModule/2.0.0')
        Test-Path $workRoot | Should -BeFalse
    }

    It 'starts each workspace with independent lifecycle state' {
        $workspace.Reinstall = $true
        $workspace.Journal = @{
            State = 'Prepared'
        }
        $workspace.Lock = [object]::new()
        $fresh = ConvertTo-InstallationWorkspace $plan $dataRoot $workRoot

        $fresh.Reinstall | Should -BeFalse
        $fresh.Reinstall | Should -BeOfType ([bool])
        ($null -eq $fresh.Journal) | Should -BeTrue
        ($null -eq $fresh.Lock) | Should -BeTrue
        $fresh.RecoveryStatus | Should -BeExactly 'NotRequired'
        $fresh.RequiresLicenseAcceptance | Should -BeFalse
        $fresh.RequiresLicenseAcceptance | Should -BeOfType ([bool])
    }
}
