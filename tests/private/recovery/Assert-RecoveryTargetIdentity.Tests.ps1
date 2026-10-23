BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-RecoveryTargetIdentity' -Tag 'PMU' {
    It 'permits a provider-truncated manifest for safe path-owned rollback' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        [IO.File]::WriteAllText($operation.Plan.InstalledManifestPath, '@{partial')
        { Assert-RecoveryTargetIdentity $operation.Journal } | Should -Not -Throw
    }
}
