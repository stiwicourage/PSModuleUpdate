BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-RecoveryInstallationObservation' -Tag 'PMU' {
    It 'derives a planning identity from a verified backup without changing disk' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $observation = Get-RecoveryInstallationObservation $operation.Journal
        $observation.FullVersion | Should -Be '2.0.0-preview.1'
        $operation.Journal.State | Should -Be 'ReplacementInProgress'
    }

    It 'projects the verified previous identity at the target path rather than the backup path' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $journal = $operation.Journal

        $observation = Get-RecoveryInstallationObservation $journal

        $observation.FullVersion | Should -BeExactly $journal.PreviousVersion
        $observation.Guid | Should -Be ([guid]$journal.ModuleGuid)
        $observation.Scope | Should -BeExactly $journal.Scope
        $observation.Root | Should -BeExactly $journal.DestinationRoot
        $expectedManifest = Join-Path $journal.TargetPath "$($journal.ModuleName).psd1"
        $observation.ManifestPath | Should -BeExactly $expectedManifest
        $observation.PSObject.Properties.Name | Should -Be @(
            'FullVersion', 'NumericVersion', 'Prerelease', 'Scope', 'Root', 'ManifestPath', 'Guid'
        )
    }

    It 'returns no observation for a null journal' {
        @(Get-RecoveryInstallationObservation $null).Count | Should -Be 0
    }
}
