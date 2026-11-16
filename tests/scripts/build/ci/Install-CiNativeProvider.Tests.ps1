BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Install-CiPowerShell.ps1')

    function Initialize-NativeOverlayFixture {
        param([string]$Path, [string]$Version = '2.2.6')
        $owner = New-CiDependencyRoot -Path $Path
        $manifest = Join-Path $Path 'Modules/PowerShellGet/PowerShellGet.psd1'
        New-Item -ItemType Directory -Path (Split-Path $manifest) -Force | Out-Null
        "@{ ModuleVersion = '$Version' }" | Set-Content -LiteralPath $manifest
        return @{ directory = $owner.Path; runtimeIdentifier = 'osx-arm64'; Owner = $owner }
    }

    function Write-NativeOverlayPayload {
        param([string]$Path, [string]$Version)
        $directory = Join-Path $Path 'PowerShellGet/2.2.5'
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        "@{ ModuleVersion = '$Version' }" | Set-Content -LiteralPath (Join-Path $directory 'PowerShellGet.psd1')
    }
}

Describe 'Owned qualified native overlay' -Tag 'CiNativeOverlay' {
    BeforeEach {
        $script:stagePath = $null
        Mock Get-PSRepository { @{ SourceLocation = 'https://www.powershellgallery.com/api/v2'; InstallationPolicy = 'Untrusted' } }
        Mock Assert-CiDependencyClosure {}
        Mock Save-Module {
            $script:stagePath = $Path
            Write-NativeOverlayPayload -Path $Path -Version '2.2.5'
        }
        Mock Read-CiNativeProviderProbe {
            @{
                name = 'PowerShellGet'
                actualVersion = '2.2.5'
                manifestPath = $ManifestPath
                runtimeDirectory = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ManifestPath))
            }
        }
    }

    It 'installs the trusted exact payload into only the owned flat runtime and observes the selected probe' {
        $installation = Initialize-NativeOverlayFixture -Path (Join-Path $TestDrive 'pmu-ci-modules-runtime-flat')
        $record = Install-CiNativeProvider -Installation $installation
        $record.archiveBundledVersion | Should -Be '2.2.6'
        $record.actualVersion | Should -Be '2.2.5'
        $record.sourceUri | Should -BeExactly 'https://www.powershellgallery.com/api/v2'
        $record.manifestPath | Should -Be (Join-Path $installation.directory 'Modules/PowerShellGet/PowerShellGet.psd1')
        (Import-PowerShellDataFile $record.manifestPath).ModuleVersion | Should -Be '2.2.5'
        Test-Path (Join-Path $installation.directory 'Modules/PowerShellGet/2.2.5') | Should -BeFalse
        Test-Path $script:stagePath | Should -BeFalse
        Should -Invoke Save-Module -Times 1 -Exactly -ParameterFilter { $Name -eq 'PowerShellGet' -and $RequiredVersion -eq '2.2.5' -and $Repository -eq 'PSGallery' }
        Should -Invoke Read-CiNativeProviderProbe -Times 1 -Exactly -ParameterFilter { $Executable -eq (Join-Path $installation.directory 'pwsh') }
    }

    It 'rejects a wrong staged manifest and always cleans staging without touching the bundled provider' {
        Mock Save-Module { $script:stagePath = $Path; Write-NativeOverlayPayload -Path $Path -Version '2.2.6' }
        $installation = Initialize-NativeOverlayFixture -Path (Join-Path $TestDrive 'pmu-ci-modules-runtime-wrong')
        { Install-CiNativeProvider -Installation $installation } | Should -Throw '*2.2.5*'
        Test-Path $script:stagePath | Should -BeFalse
        (Import-PowerShellDataFile (Join-Path $installation.directory 'Modules/PowerShellGet/PowerShellGet.psd1')).ModuleVersion | Should -Be '2.2.6'
        Should -Invoke Read-CiNativeProviderProbe -Times 0
    }

    It 'rejects a linked destination or ancestor: <RelativePath>' -ForEach @(
        @{ RelativePath = 'Modules/PowerShellGet' }
        @{ RelativePath = 'Modules' }
    ) {
        $installation = Initialize-NativeOverlayFixture -Path (Join-Path $TestDrive ('pmu-ci-modules-runtime-link-' + $RelativePath.Replace('/', '-')))
        $outside = Join-Path $TestDrive ('shared-' + $RelativePath.Replace('/', '-'))
        New-Item -ItemType Directory -Path $outside | Out-Null
        $destination = Join-Path $installation.directory $RelativePath
        Remove-Item -LiteralPath $destination -Recurse
        New-Item -ItemType SymbolicLink -Path $destination -Target $outside | Out-Null
        { Install-CiNativeProvider -Installation $installation } | Should -Throw '*link*'
        Test-Path $outside | Should -BeTrue
        Should -Invoke Save-Module -Times 0
    }

    It 'refuses an ambient runtime without ownership before downloading' {
        { Install-CiNativeProvider -Installation @{ directory = $PSHOME; runtimeIdentifier = 'osx-arm64' } } | Should -Throw
        Should -Invoke Save-Module -Times 0
    }

    It 'rejects a linked staged manifest and removes its owned staging root' {
        $outside = Join-Path $TestDrive 'shared-native.psd1'
        "@{ ModuleVersion = '2.2.5' }" | Set-Content -LiteralPath $outside
        Mock Save-Module {
            $script:stagePath = $Path
            Write-NativeOverlayPayload -Path $Path -Version '2.2.5'
            $manifest = Join-Path $Path 'PowerShellGet/2.2.5/PowerShellGet.psd1'
            Remove-Item -LiteralPath $manifest
            New-Item -ItemType SymbolicLink -Path $manifest -Target $outside | Out-Null
        }
        $installation = Initialize-NativeOverlayFixture -Path (Join-Path $TestDrive 'pmu-ci-modules-runtime-staged-link')
        { Install-CiNativeProvider -Installation $installation } | Should -Throw '*link*'
        Test-Path $script:stagePath | Should -BeFalse
        Test-Path $outside | Should -BeTrue
    }

    It 'rejects incorrect observed probe evidence: <Field>' -ForEach @(
        @{ Field = 'actualVersion'; Value = '2.2.6' }
        @{ Field = 'manifestPath'; Value = '/shared/PowerShellGet.psd1' }
        @{ Field = 'name'; Value = 'Other' }
        @{ Field = 'runtimeDirectory'; Value = '/shared' }
    ) {
        Mock Read-CiNativeProviderProbe {
            $record = @{
                name = 'PowerShellGet'
                actualVersion = '2.2.5'
                manifestPath = $ManifestPath
                runtimeDirectory = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ManifestPath))
            }

            $record[$Field] = $Value
            return $record
        }
        $installation = Initialize-NativeOverlayFixture -Path (Join-Path $TestDrive "pmu-ci-modules-runtime-probe-$Field")
        { Install-CiNativeProvider -Installation $installation } | Should -Throw '*probe*'
        Test-Path $script:stagePath | Should -BeFalse
    }
}

Describe 'Selected native import probe protocol' -Tag 'CiNativeOverlay' {
    It 'requests the exact flat manifest and qualified import version in the selected child command' {
        $command = Get-CiNativeProviderProbeCommand -ManifestPath "/owned/runtime's/Modules/PowerShellGet/PowerShellGet.psd1"
        $command | Should -Match "Import-Module '/owned/runtime''s/Modules/PowerShellGet/PowerShellGet.psd1' -RequiredVersion 2.2.5"
        $command | Should -Match '\$module.Version.ToString\(\)'
        $command | Should -Match '\$module.ModuleBase'
        $command | Should -Match 'runtimeDirectory = \$PSHOME'
    }

    It 'propagates the selected child import failure rather than publishing assumed metadata' {
        Mock Get-CiNativeProviderProbeCommand { 'exit 7' }
        { Read-CiNativeProviderProbe -Executable (Get-Process -Id $PID).Path -ManifestPath '/unused' } | Should -Throw '*import probe failed*'
    }

    It 'rejects malformed selected child evidence' {
        Mock Get-CiNativeProviderProbeCommand { "'not json'" }
        { Read-CiNativeProviderProbe -Executable (Get-Process -Id $PID).Path -ManifestPath '/unused' } | Should -Throw
    }
}
