BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Install-CiPowerShellModules.ps1')
}

Describe 'Get-CiModuleInstallParameter' -Tag 'BuildTooling' {
    It 'pins Pester to the version used by the repository quality pipeline' {
        $parameter = Get-CiModuleInstallParameter -Name 'Pester'
        $parameter.RequiredVersion | Should -Be '5.7.1'
    }

    It 'pins PSResourceGet to the version required by the local provider fixtures' {
        (Get-CiModuleInstallParameter -Name 'Microsoft.PowerShell.PSResourceGet').RequiredVersion | Should -Be '1.2.0'
    }

    It 'installs other modules from PSGallery for the current user without prereleases' {
        $parameter = Get-CiModuleInstallParameter -Name 'NovaModuleTools'

        $parameter.Repository | Should -Be 'PSGallery'
        $parameter.Scope | Should -Be 'CurrentUser'
        $parameter.ContainsKey('AllowPrerelease') | Should -BeFalse
        $parameter.ContainsKey('RequiredVersion') | Should -BeFalse
    }
}
