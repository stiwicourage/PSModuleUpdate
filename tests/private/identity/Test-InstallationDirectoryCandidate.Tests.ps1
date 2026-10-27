BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-InstallationDirectoryCandidate' -Tag 'PMU', 'InstalledLayout' {
    It 'classifies <name> with manifest <manifest> as candidate <expected>' -ForEach @(
        @{
            name = 'en-US'
            manifest = $false
            expected = $false
        }
        @{
            name = 'resources'
            manifest = $false
            expected = $false
        }
        @{
            name = '0.1.0'
            manifest = $false
            expected = $true
        }
        @{
            name = 'unexpected'
            manifest = $true
            expected = $true
        }
    ) {
        $root = Join-Path $TestDrive ([guid]::NewGuid())
        $directory = New-Item "$root/$name" -ItemType Directory -Force
        if ($manifest) {
            $null = New-Item "$directory/FixtureModule.psd1" -ItemType File
        }
        Test-InstallationDirectoryCandidate $directory 'FixtureModule' | Should -Be $expected
    }
}
