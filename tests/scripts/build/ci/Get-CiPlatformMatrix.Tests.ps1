BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Get-CiPlatformMatrix.ps1')
    $script:lanePath = Join-Path $root 'scripts/build/ci/CiLanes.json'
}

Describe 'Get-CiPlatformMatrix' -Tag 'BuildTooling' {
    It 'defines exactly the six approved lanes' {
        $laneList = @((Get-Content -LiteralPath $script:lanePath -Raw | ConvertFrom-Json).lanes)
        $actual = $laneList | ForEach-Object { '{0}|{1}|{2}' -f $_.os, $_.architecture, $_.powershell }

        $actual | Should -HaveCount 6
        $actual | Should -Contain 'Windows|X64|7.4'
        $actual | Should -Contain 'Windows|X64|stable'
        $actual | Should -Contain 'Linux|X64|7.4'
        $actual | Should -Contain 'Linux|X64|stable'
        $actual | Should -Contain 'macOS|Arm64|7.4'
        $actual | Should -Contain 'macOS|Arm64|stable'
    }

    It 'uses pinned runner labels and never a moving latest alias' {
        $laneList = @((Get-Content -LiteralPath $script:lanePath -Raw | ConvertFrom-Json).lanes)
        $laneList.runner | Should -Not -Match 'latest'
        ($laneList | Where-Object os -eq 'macOS').runner | Should -Not -Match 'intel'
    }

    It 'emits compressed matrix JSON that contains every lane field the workflow needs' {
        $matrix = Get-CiPlatformMatrix -LanePath $script:lanePath | ConvertFrom-Json

        @($matrix.include) | Should -HaveCount 6
        foreach ($entry in $matrix.include) {
            foreach ($field in @('id', 'name', 'runner', 'os', 'architecture', 'runtimeIdentifier', 'powershell')) {
                $entry.$field | Should -Not -BeNullOrEmpty -Because "lane '$($entry.id)' needs '$field'"
            }
        }
    }

    It 'rejects duplicate lane identifiers' {
        $path = Join-Path $TestDrive 'dup.json'
        $lane = @{
            id = 'a'
            name = 'a'
            runner = 'r'
            os = 'Linux'
            architecture = 'X64'
            runtimeIdentifier = 'linux-x64'
            powershell = '7.4'
        }
        @{ lanes = @($lane, $lane) } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $path

        { Get-CiPlatformMatrix -LanePath $path } | Should -Throw '*duplicate*'
    }

    It 'rejects a moving latest runner label' {
        $path = Join-Path $TestDrive 'latest.json'
        $lane = @{
            id = 'a'
            name = 'a'
            runner = 'macos-latest'
            os = 'macOS'
            architecture = 'Arm64'
            runtimeIdentifier = 'osx-arm64'
            powershell = '7.4'
        }
        @{ lanes = @($lane) } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $path

        { Get-CiPlatformMatrix -LanePath $path } | Should -Throw '*moving*'
    }
}
