BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Assert-RecoveryTargetIdentity' -Tag 'PMU' {
    It 'permits a provider-truncated manifest for safe path-owned rollback' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        [IO.File]::WriteAllText($operation.Plan.InstalledManifestPath, '@{partial')
        { Assert-RecoveryTargetIdentity $operation.Journal } | Should -Not -Throw
    }
    It 'permits partial surviving identity: <Manifest>' -TestCases @(
        @{
            Manifest = @{
                GUID = 'ABC'
            }
        }
        @{
            Manifest = @{
                ModuleVersion = '2.0.0'
            }
        }
        @{
            Manifest = @{
                GUID = ''
                ModuleVersion = $false
            }
        }
    ) {
        param($Manifest)
        $script:survivingManifest = $Manifest
        Mock Get-SurvivingManifestData {
            $script:survivingManifest
        }
        $journal = [pscustomobject]@{
            TargetPath = $TestDrive
            ModuleName = 'Fixture'
            ModuleGuid = 'abc'
            TargetNumericVersion = '2.0.0'
            PreviousVersion = '1.0.0'
            TargetVersion = '2.0.0'
        }
        { Assert-RecoveryTargetIdentity $journal } | Should -Not -Throw
    }
    It 'rejects surviving numeric identity before full-version validation' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        Mock Get-SurvivingManifestData {
            @{
                ModuleVersion = '3.0.0'
            }
        }
        { Assert-RecoveryTargetIdentity $operation.Journal } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch' -ExpectedMessage 'Recovery refuses to delete an installation with an unexpected manifest identity.'
    }
}
