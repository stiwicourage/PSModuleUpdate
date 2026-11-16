BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-RecoveryRestoration' -Tag 'PMU' {
    Context 'Verified restoration' {
        It 'records recovery completed after restoring previous content' {
            $operation = Initialize-PMURecoveryFixture $TestDrive
            Invoke-RecoveryRestoration $operation.Journal $operation
            $operation.Journal.State | Should -Be 'RecoveryCompleted'
        }
    }
    It 'preserves the journal and surviving backup when restoration fails' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $manifest = Join-Path $operation.BackupPath 'FixtureModule.psd1'
        $hash = (Get-FileHash -LiteralPath $manifest).Hash
        Mock Restore-InstallationBackup { throw [IO.IOException]::new('Private restoration details.') }
        $failure = { Invoke-RecoveryRestoration $operation.Journal $operation } |
            Should -Throw -ErrorId 'PMU.RecoveryFailed' -PassThru
        "$failure" | Should -Not -Match 'Private restoration details'
        $operation.Journal.State | Should -BeExactly 'ReplacementInProgress'
        Test-Path -LiteralPath $operation.Journal.JournalPath | Should -BeTrue
        (Get-FileHash -LiteralPath $manifest).Hash | Should -BeExactly $hash
    }
}
