BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-InstalledModuleIdentityList' -Tag 'PMU' {
    BeforeEach {
        $script:installationRoot = Join-Path $TestDrive ([guid]::NewGuid())
        $null = New-Item $script:installationRoot -ItemType Directory
        Mock Resolve-ModuleInstallationRoot { $script:installationRoot }
    }
    It 'reads the manifest prerelease, not the numeric directory name' {
        $null = Initialize-PMUTestPackage $script:installationRoot '2.0.0-preview.10'
        $identity = Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers'
        $identity.FullVersion | Should -Be '2.0.0-preview.10'
        $identity.Scope | Should -Be 'AllUsers'
    }
    It 'rejects a directory whose name differs from the manifest numeric version' {
        $path = Initialize-PMUTestPackage $script:installationRoot '2.0.0'
        Rename-Item -LiteralPath $path -NewName '9.9.9'
        { Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers' } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }

    It 'discovers a version beside flat-installation resources without changing the layout' -Tag 'InstalledLayout' {
        $path = Initialize-PMUTestPackage $script:installationRoot '0.1.0'
        $moduleRoot = Split-Path -Parent $path
        Copy-Item "$path/FixtureModule.psd1" $moduleRoot
        $null = New-Item "$moduleRoot/en-US", "$moduleRoot/resources" -ItemType Directory
        $identity = @(Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers')
        $identity.Count | Should -Be 1
        $identity[0].FullVersion | Should -Be '0.1.0'
        $identity[0].ManifestPath | Should -Be (Join-Path $path 'FixtureModule.psd1')
        "$moduleRoot/en-US", "$moduleRoot/resources", "$moduleRoot/FixtureModule.psd1" |
            ForEach-Object { $_ | Should -Exist }
    }

    It 'still rejects a numeric version directory without a manifest' -Tag 'InstalledLayout' {
        $null = New-Item "$script:installationRoot/FixtureModule/0.1.0" -ItemType Directory -Force
        { Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers' } |
            Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch'
    }

    It 'still rejects a nonnumeric directory containing a module manifest' -Tag 'InstalledLayout' {
        $path = Initialize-PMUTestPackage $script:installationRoot '0.1.0'
        Rename-Item -LiteralPath $path -NewName 'unexpected'
        { Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers' } |
            Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }

    It 'excludes the exact target before manifest validation and preserves remaining candidate order' {
        $excluded = Initialize-PMUTestPackage $script:installationRoot '1.0.0'
        $newer = Initialize-PMUTestPackage $script:installationRoot '3.0.0'
        $older = Initialize-PMUTestPackage $script:installationRoot '2.0.0'
        Set-Content (Join-Path $excluded 'FixtureModule.psd1') 'not a manifest'
        $script:orderedCandidates = Get-Item $excluded, $newer, $older
        Mock Get-ChildItem { $script:orderedCandidates }

        $observations = @(Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers' $excluded)

        $observations.FullVersion | Should -Be @('3.0.0', '2.0.0')
        $observations.ManifestPath | Should -Be @(
            (Join-Path $newer 'FixtureModule.psd1')
            (Join-Path $older 'FixtureModule.psd1')
        )
    }

    It 'does not exclude a candidate whose path differs only by case' {
        $path = Initialize-PMUTestPackage $script:installationRoot '2.0.0'
        $excluded = $path.ToUpperInvariant()

        $observations = @(Get-InstalledModuleIdentityList 'FixtureModule' 'AllUsers' $excluded)

        $observations.Count | Should -Be 1
        $observations[0].ManifestPath | Should -BeExactly (Join-Path $path 'FixtureModule.psd1')
    }
}
