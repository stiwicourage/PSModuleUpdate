BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-PlanningInstallationSnapshot' -Tag 'PMU' {
    BeforeEach {
        $script:installed = [pscustomobject]@{
            ManifestPath = Join-Path $TestDrive 'Modules/FixtureModule/2.0.0/FixtureModule.psd1'
            NumericVersion = '2.0.0'
        }
        $script:inventory = [pscustomobject]@{
            RelativePath = 'FixtureModule.psd1'
        }
        Mock Select-NewestInstallation {
            $script:installed
        }
        Mock Get-FileTreeInventory {
            $script:inventory
        }
    }

    It 'uses the <Label> inventory and retains snapshot references' -ForEach @(
        @{
            Label = 'live installation without a journal'
            FromBackup = $false
            HasJournal = $false
            TargetVersion = '2.0.0'
            UseBackup = $false
        }
        @{
            Label = 'live installation with an inactive journal'
            FromBackup = $false
            HasJournal = $true
            TargetVersion = '2.0.0'
            UseBackup = $false
        }
        @{
            Label = 'matching recovery backup'
            FromBackup = $true
            HasJournal = $true
            TargetVersion = '2.0.0'
            UseBackup = $true
        }
        @{
            Label = 'newer side-by-side installation'
            FromBackup = $true
            HasJournal = $true
            TargetVersion = '1.0.0'
            UseBackup = $false
        }
    ) {
        $journal = $null
        if ($HasJournal) {
            $journal = [pscustomobject]@{
                TargetNumericVersion = $TargetVersion
                BackupPath = Join-Path $TestDrive 'data/backup'
            }
        }
        $state = [pscustomobject]@{
            Selected = @($installed)
            FromBackup = $FromBackup
            Journal = $journal
        }
        $snapshot = Get-PlanningInstallationSnapshot $state
        $expectedPath = Split-Path -Parent $installed.ManifestPath
        if ($UseBackup) {
            $expectedPath = $journal.BackupPath
        }
        Should -Invoke Get-FileTreeInventory -Times 1 -Exactly -ParameterFilter {
            $Path -ceq $expectedPath
        }
        @($snapshot.PSObject.Properties.Name) | Should -Be @('Installed', 'InstalledTree', 'RecoveryJournal')
        [object]::ReferenceEquals($snapshot.Installed, $installed) | Should -BeTrue
        $snapshot.InstalledTree.GetType().FullName | Should -Be 'System.Object[]'
        [object]::ReferenceEquals($snapshot.InstalledTree[0], $inventory) | Should -BeTrue
        if ($FromBackup) {
            [object]::ReferenceEquals($snapshot.RecoveryJournal, $journal) | Should -BeTrue
        } else {
            $snapshot.RecoveryJournal | Should -BeNullOrEmpty
        }
    }

    It 'retains an empty inventory as an array rather than null' {
        Mock Get-FileTreeInventory {}
        $state = [pscustomobject]@{
            Selected = @($installed)
            FromBackup = $false
            Journal = $null
        }

        $snapshot = Get-PlanningInstallationSnapshot $state

        $snapshot.InstalledTree.GetType().FullName | Should -Be 'System.Object[]'
        $snapshot.InstalledTree.Count | Should -Be 0
    }

    It 'propagates inventory failures without a partial snapshot' {
        Mock Get-FileTreeInventory {
            throw 'inventory failure'
        }
        $state = [pscustomobject]@{
            Selected = @($installed)
            FromBackup = $false
            Journal = $null
        }

        { Get-PlanningInstallationSnapshot $state } | Should -Throw '*inventory failure*'
    }
}
