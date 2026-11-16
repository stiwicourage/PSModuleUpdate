BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Install-CiPowerShell.ps1')
    $script:pinPath = Join-Path $root 'scripts/build/ci/PowerShellVersions.json'
}

Describe 'Qualified runtime installation transaction' -Tag 'CiNativeOverlay' {
    BeforeEach {
        $script:installRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:installRoot | Out-Null
        Mock Resolve-CiPowerShellRelease {
            @{ Version = '7.7.0'; FileName = 'archive.tar.gz'; Sha256 = ('a' * 64); HashSource = 'official hashes' }
        }
        Mock Invoke-WebRequest {}
        Mock Assert-CiFileHash {}
        Mock Expand-CiPowerShellArchive {}
        Mock Install-CiNativeProvider { @{ actualVersion = '2.2.5' } }
        Mock Assert-CiInstalledPowerShell {}
    }

    It 'overlays before returning the unchanged checksum and runtime identity' {
        $installation = Install-CiPowerShell -Channel stable -RuntimeIdentifier osx-arm64 -InstallRoot $script:installRoot -PinPath $script:pinPath
        $installation.nativeProvider.actualVersion | Should -Be '2.2.5'
        $installation.sha256 | Should -Be ('a' * 64)
        $installation.version | Should -Be '7.7.0'
        $installation.channel | Should -Be 'stable'
        Should -Invoke Assert-CiFileHash -Times 1 -Exactly -ParameterFilter { $ExpectedSha256 -eq ('a' * 64) }
        Should -Invoke Install-CiNativeProvider -Times 1 -Exactly
    }

    It 'cleans only the newly extracted owned runtime when the overlay or probe fails' {
        Mock Install-CiNativeProvider { throw 'native probe failed' }
        $sentinel = Join-Path $script:installRoot 'shared.txt'
        Set-Content $sentinel 'preserve'
        { Install-CiPowerShell -Channel stable -RuntimeIdentifier osx-arm64 -InstallRoot $script:installRoot -PinPath $script:pinPath } | Should -Throw '*native probe failed*'
        Test-Path $sentinel | Should -BeTrue
        @(Get-ChildItem $script:installRoot -Directory -Filter 'pmu-ci-modules-*').Count | Should -Be 0
    }

    It 'does not extract or overlay a checksum failure' {
        Mock Assert-CiFileHash { throw 'checksum mismatch' }
        { Install-CiPowerShell -Channel stable -RuntimeIdentifier osx-arm64 -InstallRoot $script:installRoot -PinPath $script:pinPath } | Should -Throw '*checksum mismatch*'
        Should -Invoke Expand-CiPowerShellArchive -Times 0
        Should -Invoke Install-CiNativeProvider -Times 0
    }

    It 'cleans only its fresh runtime when extraction fails' {
        Mock Expand-CiPowerShellArchive { throw 'extraction failed' }
        { Install-CiPowerShell -Channel stable -RuntimeIdentifier osx-arm64 -InstallRoot $script:installRoot -PinPath $script:pinPath } | Should -Throw '*extraction failed*'
        Test-Path $script:installRoot | Should -BeTrue
        @(Get-ChildItem $script:installRoot -Directory -Filter 'pmu-ci-modules-*').Count | Should -Be 0
        Should -Invoke Install-CiNativeProvider -Times 0
    }

    It 'cleans only its fresh runtime when the original runtime identity probe fails' {
        Mock Assert-CiInstalledPowerShell { throw 'runtime identity differs' }
        { Install-CiPowerShell -Channel stable -RuntimeIdentifier osx-arm64 -InstallRoot $script:installRoot -PinPath $script:pinPath } | Should -Throw '*runtime identity differs*'
        Test-Path $script:installRoot | Should -BeTrue
        @(Get-ChildItem $script:installRoot -Directory -Filter 'pmu-ci-modules-*').Count | Should -Be 0
    }
}

Describe 'Get-CiPowerShellAssetName' -Tag 'BuildTooling' {
    It 'names the official archive for <RuntimeIdentifier>' -ForEach @(
        @{
            RuntimeIdentifier = 'win-x64'
            Expected = 'PowerShell-7.4.21-win-x64.zip'
        }
        @{
            RuntimeIdentifier = 'linux-x64'
            Expected = 'powershell-7.4.21-linux-x64.tar.gz'
        }
        @{
            RuntimeIdentifier = 'osx-arm64'
            Expected = 'powershell-7.4.21-osx-arm64.tar.gz'
        }
    ) {
        Get-CiPowerShellAssetName -Version '7.4.21' -RuntimeIdentifier $RuntimeIdentifier | Should -Be $Expected
    }

    It 'rejects an unsupported runtime identifier' {
        { Get-CiPowerShellAssetName -Version '7.4.21' -RuntimeIdentifier 'freebsd-x64' } | Should -Throw '*Unsupported*'
    }
}

Describe 'Get-CiPinnedPowerShellRelease' -Tag 'BuildTooling' {
    It 'pins the 7.4 channel to an explicit patch and a checksum for every lane runtime' {
        foreach ($runtime in @('win-x64', 'linux-x64', 'osx-arm64')) {
            $release = Get-CiPinnedPowerShellRelease -PinPath $script:pinPath -Channel '7.4' -RuntimeIdentifier $runtime

            $release.Version | Should -Match '^7\.4\.\d+$'
            $release.FileName | Should -Be (Get-CiPowerShellAssetName -Version $release.Version -RuntimeIdentifier $runtime)
            $release.Sha256 | Should -Match '^[0-9a-f]{64}$'
        }
    }

    It 'fails when the channel is not pinned' {
        { Get-CiPinnedPowerShellRelease -PinPath $script:pinPath -Channel '7.2' -RuntimeIdentifier 'win-x64' } | Should -Throw '*not pinned*'
    }
}

Describe 'Get-CiExpectedSha256' -Tag 'BuildTooling' {
    It 'reads the checksum for one file from an official hash list' {
        $line = @(
            ('a' * 64) + ' *powershell-7.6.8-linux-arm64.tar.gz'
            ('B' * 64) + ' *powershell-7.6.8-linux-x64.tar.gz'
        )
        Get-CiExpectedSha256 -HashLine $line -FileName 'powershell-7.6.8-linux-x64.tar.gz' | Should -Be ('b' * 64)
    }

    It 'fails when the file has no checksum entry' {
        { Get-CiExpectedSha256 -HashLine @(('a' * 64) + ' *other.zip') -FileName 'missing.zip' } | Should -Throw '*No checksum*'
    }
}

Describe 'Assert-CiFileHash' -Tag 'BuildTooling' {
    It 'accepts a file whose SHA-256 matches regardless of case' {
        $path = Join-Path $TestDrive 'payload.bin'
        Set-Content -LiteralPath $path -Value 'payload' -NoNewline
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash

        { Assert-CiFileHash -Path $path -ExpectedSha256 $hash.ToLowerInvariant() } | Should -Not -Throw
    }

    It 'rejects a file whose SHA-256 differs' {
        $path = Join-Path $TestDrive 'tampered.bin'
        Set-Content -LiteralPath $path -Value 'tampered' -NoNewline

        { Assert-CiFileHash -Path $path -ExpectedSha256 ('0' * 64) } | Should -Throw '*checksum mismatch*'
    }
}

Describe 'Resolve-CiPowerShellVersionTag' -Tag 'BuildTooling' {
    It 'strips the leading v from a release tag' {
        Resolve-CiPowerShellVersionTag -Tag 'v7.6.8' | Should -Be '7.6.8'
    }

    Describe 'Assert-CiInstalledPowerShell' -Tag 'BuildTooling' {
        It 'rejects a matching version running on the wrong OS or architecture' {
            $installation = @{
                directory = $PSHOME
                version = $PSVersionTable.PSVersion.ToString()
                runtimeIdentifier = if ($IsWindows) {
                    'linux-x64'
                } else {
                    'win-x64'
                }
            }
            # The executable exists, but its requested runtime identifier is deliberately wrong.
            if (-not $IsWindows) {
                $installation.runtimeIdentifier = 'linux-x64'
            }
            if ($IsLinux) {
                $installation.runtimeIdentifier = 'osx-arm64'
            }
            { Assert-CiInstalledPowerShell -Installation $installation } | Should -Throw
        }
    }

    It 'rejects preview tags because stable lanes must not run previews' {
        { Resolve-CiPowerShellVersionTag -Tag 'v7.7.0-preview.5' } | Should -Throw '*stable*'
    }
}
