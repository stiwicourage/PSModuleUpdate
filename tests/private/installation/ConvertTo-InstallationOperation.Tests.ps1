BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-InstallationOperation' -Tag 'PMU' {
    It 'groups in-memory inputs without writing any persistent state' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.LockPath | Should -Be (Join-Path $operation.WorkRoot 'operation.lock')
        Test-Path $operation.WorkRoot | Should -BeFalse
    }

    It 'retains input references and the original flat property order' {
        $plan = [pscustomobject]@{
            Scope = 'CurrentUser'
            ModuleName = 'FixtureModule'
            TargetNumericVersion = '2.0.0'
        }
        $record = [pscustomobject]@{
            InstalledTree = @('original')
        }
        $consent = @{
            AcceptLicense = $true
        }
        $credential = [pscredential]::new('fixture', [securestring]::new())
        Mock Resolve-PMUDataRoot { Join-Path $TestDrive 'data' }
        Mock Get-InstallationLockIdentity { 'fixture-lock' }

        $operation = ConvertTo-InstallationOperation $plan $record $consent $credential

        $operation.GetType() | Should -Be ([System.Management.Automation.PSCustomObject])
        [object]::ReferenceEquals($operation.Plan, $plan) | Should -BeTrue
        [object]::ReferenceEquals($operation.Record, $record) | Should -BeTrue
        [object]::ReferenceEquals($operation.Consent, $consent) | Should -BeTrue
        [object]::ReferenceEquals($operation.Credential, $credential) | Should -BeTrue
        $operation.RepositoryName | Should -BeNullOrEmpty
        $expectedNames = @(
            'Plan', 'Record', 'Consent', 'Credential', 'RepositoryName'
            'DataRoot', 'WorkRoot', 'LockPath', 'JournalPath', 'StageRoot', 'BackupPath'
            'Reinstall', 'Journal', 'Lock', 'StagedPath', 'RecoveryStatus', 'RequiresLicenseAcceptance'
        )
        ($operation.PSObject.Properties.Name -join ',') | Should -BeExactly ($expectedNames -join ',')
    }
}
