BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Assert-ManifestReadHash' -Tag 'PMU', 'PMUTargetManifest' {
    It 'detects content changes while a manifest is being read' {
        $path = Join-Path $TestDrive 'manifest.psd1'
        [IO.File]::WriteAllText($path, '@{ One = 1 }')
        $hash = (Get-FileHash $path -Algorithm SHA256).Hash
        {
            Assert-ManifestReadHash $path $hash
        } | Should -Not -Throw
        [IO.File]::WriteAllText($path, '@{ One = 2 }')
        {
            Assert-ManifestReadHash $path $hash
        } | Should -Throw -ErrorId PMU.TargetManifestChanged
    }
}
