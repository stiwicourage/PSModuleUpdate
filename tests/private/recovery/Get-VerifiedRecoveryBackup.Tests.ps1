BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-VerifiedRecoveryBackup' -Tag 'PMU' {
    Context 'Verified previous identity' {
        It 'returns the previous manifest only after tree verification' {
            $operation = Initialize-PMURecoveryFixture $TestDrive
            (Get-VerifiedRecoveryBackup $operation.Journal).Version.FullVersion | Should -Be '2.0.0-preview.1'
        }
    }
    It 'preserves the surviving backup when its <Field> differs from the recovery journal' -ForEach @(
        @{ Field = 'ModuleGuid'; Value = '22222222-2222-2222-2222-222222222222' }
        @{ Field = 'PreviousVersion'; Value = '2.0.0-preview.9' }
    ) {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $manifest = Join-Path $operation.BackupPath 'FixtureModule.psd1'
        $hash = (Get-FileHash -LiteralPath $manifest).Hash
        $operation.Journal.$Field = $Value
        { Get-VerifiedRecoveryBackup $operation.Journal 'PMU.RecoveryRequired' } |
            Should -Throw -ErrorId 'PMU.RecoveryRequired' -ExpectedMessage 'The surviving backup does not match the previous identity.'
        (Get-FileHash -LiteralPath $manifest).Hash | Should -BeExactly $hash
    }
}
