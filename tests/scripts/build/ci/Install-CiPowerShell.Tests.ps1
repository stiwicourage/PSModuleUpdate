BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Install-CiPowerShell.ps1')
    $script:pinPath = Join-Path $root 'scripts/build/ci/PowerShellVersions.json'
}

Describe 'Get-CiPowerShellAssetName' -Tag 'BuildTooling' {
    It 'names the official archive for <RuntimeIdentifier>' -ForEach @(
        @{ RuntimeIdentifier = 'win-x64'; Expected = 'PowerShell-7.4.21-win-x64.zip' }
        @{ RuntimeIdentifier = 'linux-x64'; Expected = 'powershell-7.4.21-linux-x64.tar.gz' }
        @{ RuntimeIdentifier = 'osx-arm64'; Expected = 'powershell-7.4.21-osx-arm64.tar.gz' }
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
                runtimeIdentifier = if ($IsWindows) { 'linux-x64' } else { 'win-x64' }
            }
            # The executable exists, but its requested runtime identifier is deliberately wrong.
            if (-not $IsWindows) { $installation.runtimeIdentifier = 'linux-x64' }
            if ($IsLinux) { $installation.runtimeIdentifier = 'osx-arm64' }
            { Assert-CiInstalledPowerShell -Installation $installation } | Should -Throw
        }
    }

    It 'rejects preview tags because stable lanes must not run previews' {
        { Resolve-CiPowerShellVersionTag -Tag 'v7.7.0-preview.5' } | Should -Throw '*stable*'
    }
}
