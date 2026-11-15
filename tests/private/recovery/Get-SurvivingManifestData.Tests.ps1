BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-SurvivingManifestData' -Tag 'PMU' {
    Context 'Interrupted provider files' {
        It 'returns no identity for a missing manifest rather than executing anything' {
            (Get-SurvivingManifestData "$TestDrive/absent.psd1").Count | Should -Be 0
        }
        It 'tolerates a truncated journal-owned manifest without executing its contents' {
            $path = Join-Path $TestDrive 'Fixture.psd1'
            [IO.File]::WriteAllText($path, '@{ ModuleVersion = ')
            (Get-SurvivingManifestData $path).Count | Should -Be 0
            Get-Content -LiteralPath $path -Raw | Should -BeExactly '@{ ModuleVersion = '
        }
        It 'returns surviving literal identity data from a readable manifest' {
            $path = Join-Path $TestDrive 'Fixture.psd1'
            [IO.File]::WriteAllText($path, "@{ ModuleVersion = '2.0.0'; GUID = '11111111-1111-1111-1111-111111111111' }")
            $manifest = Get-SurvivingManifestData $path
            $manifest.ModuleVersion | Should -BeExactly '2.0.0'
            $manifest.GUID | Should -BeExactly '11111111-1111-1111-1111-111111111111'
        }
    }
}
