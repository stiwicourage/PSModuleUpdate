BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Install-CiPowerShellModules.ps1')
}

Describe 'Get-CiModuleInstallParameter' -Tag 'BuildTooling' {
    It 'pins Pester to the version used by the repository quality pipeline' {
        $parameter = Get-CiModuleInstallParameter -Name 'Pester'
        $parameter.RequiredVersion | Should -Be '5.7.1'
    }

    Describe 'Save-CiPowerShellModule' -Tag 'CiProvisioning' {
        BeforeEach {
            $script:galleryPresent = $true
            $script:galleryUri = 'https://www.powershellgallery.com/api/v2'
            $script:galleryPolicy = 'Untrusted'
            $script:saveAttempts = 0
            Mock Get-PSRepository {
                if ($script:galleryPresent) {
                    [pscustomobject]@{ SourceLocation = $script:galleryUri; InstallationPolicy = $script:galleryPolicy }
                }
            }
            Mock Register-CiGallery { $script:galleryPresent = $true }
            Mock Unregister-PSRepository { $script:galleryPresent = $false }
            Mock Start-Sleep {}
            Mock Assert-CiDependencyClosure {}
            Mock Save-Module {
                if (-not $script:galleryPresent) { throw 'Unable to find repository PSGallery.' }
            }
        }

        It 'initializes a missing default Gallery before saving and removes only its own registration afterward' {
            $script:galleryPresent = $false
            $path = Join-Path $TestDrive 'pmu-ci-modules-missing-gallery'
            $owner = Save-CiPowerShellModule -Name Pester -ModuleRoot $path
            $owner.Path | Should -Be $path
            $script:galleryPresent | Should -BeFalse
            Should -Invoke Register-CiGallery -Times 1 -Exactly
            Should -Invoke Unregister-PSRepository -Times 1 -Exactly -ParameterFilter { $Name -eq 'PSGallery' }
            Should -Invoke Save-Module -Times 1 -Exactly -ParameterFilter { $RequiredVersion -eq '5.7.1' -and $Path -eq $path }
        }

        It 'preserves an existing registration and still validates the isolated dependency closure' {
            $path = Join-Path $TestDrive 'pmu-ci-modules-existing-gallery'
            $null = Save-CiPowerShellModule -Name Pester -ModuleRoot $path
            $script:galleryPresent | Should -BeTrue
            Should -Invoke Register-CiGallery -Times 0
            Should -Invoke Unregister-PSRepository -Times 0
            Should -Invoke Assert-CiDependencyClosure -Times 1 -Exactly -ParameterFilter { $ModuleRoot -eq $path }
        }

        It 'retries an interrupted package download without changing version, repository or destination' {
            Mock Save-Module {
                $script:saveAttempts++
                if ($script:saveAttempts -lt 3) { throw 'Package failed to download.' }
            }
            $path = Join-Path $TestDrive 'pmu-ci-modules-download-retry'
            $null = Save-CiPowerShellModule -Name Pester -ModuleRoot $path
            Should -Invoke Save-Module -Times 3 -Exactly -ParameterFilter {
                $Name -eq 'Pester' -and $RequiredVersion -eq '5.7.1' -and $Repository -eq 'PSGallery' -and $Path -eq $path
            }
            Should -Invoke Start-Sleep -Times 2 -Exactly
        }

        It 'stops after three failed downloads and removes the failed owned root and temporary registration' {
            $script:galleryPresent = $false
            Mock Save-Module { throw 'Persistent package download failure.' }
            $path = Join-Path $TestDrive 'pmu-ci-modules-failed-download'
            { Save-CiPowerShellModule -Name Pester -ModuleRoot $path } | Should -Throw '*Persistent package download failure*'
            Should -Invoke Save-Module -Times 3 -Exactly
            Test-Path -LiteralPath $path | Should -BeFalse
            $script:galleryPresent | Should -BeFalse
            Should -Invoke Assert-CiDependencyClosure -Times 0
        }

        It 'rejects a repointed Gallery without downloading or changing the existing registration' {
            $script:galleryUri = 'https://unexpected.invalid/v2'
            $path = Join-Path $TestDrive 'pmu-ci-modules-repointed-gallery'
            { Save-CiPowerShellModule -Name Pester -ModuleRoot $path } | Should -Throw '*official PSGallery*'
            Should -Invoke Save-Module -Times 0
            Should -Invoke Register-CiGallery -Times 0
            Should -Invoke Unregister-PSRepository -Times 0
            Test-Path -LiteralPath $path | Should -BeFalse
        }

        It 'fails and cleans up when the isolated import probe rejects the downloaded closure' {
            Mock Assert-CiDependencyClosure { throw 'Isolated dependency closure validation failed.' }
            $path = Join-Path $TestDrive 'pmu-ci-modules-failed-probe'
            { Save-CiPowerShellModule -Name Pester -ModuleRoot $path } | Should -Throw '*closure validation failed*'
            Test-Path -LiteralPath $path | Should -BeFalse
            Should -Invoke Assert-CiDependencyClosure -Times 1 -Exactly
        }

        It 'preserves a temporary registration if its <Field> changes during download' -ForEach @(
            @{ Field = 'Source'; Uri = 'https://unexpected.invalid/v2'; Policy = 'Untrusted' }
            @{ Field = 'Trust'; Uri = 'https://www.powershellgallery.com/api/v2'; Policy = 'Trusted' }
        ) {
            $script:galleryPresent = $false
            Mock Save-Module { $script:galleryUri = $Uri; $script:galleryPolicy = $Policy }
            $path = Join-Path $TestDrive "pmu-ci-modules-changed-$Field"
            { Save-CiPowerShellModule -Name Pester -ModuleRoot $path } | Should -Throw
            Should -Invoke Unregister-PSRepository -Times 0
            $script:galleryPresent | Should -BeTrue
            Test-Path -LiteralPath $path | Should -BeFalse
        }
    }

    It 'pins PSResourceGet to the version required by the local provider fixtures' {
        (Get-CiModuleInstallParameter -Name 'Microsoft.PowerShell.PSResourceGet').RequiredVersion | Should -Be '1.2.0'
    }

    It 'saves other modules from PSGallery without persistent scope or prereleases' {
        $parameter = Get-CiModuleInstallParameter -Name 'NovaModuleTools'

        $parameter.Repository | Should -Be 'PSGallery'
        $parameter.ContainsKey('Scope') | Should -BeFalse
        $parameter.ContainsKey('AllowPrerelease') | Should -BeFalse
        $parameter.ContainsKey('RequiredVersion') | Should -BeFalse
    }

    It 'requires an explicit disposable destination for saved modules' {
        $parameter = Get-CiModuleInstallParameter -Name 'Pester' -ModuleRoot $TestDrive
        $parameter.Path | Should -Be $TestDrive
    }
}
