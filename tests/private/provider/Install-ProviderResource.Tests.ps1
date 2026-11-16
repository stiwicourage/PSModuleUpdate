BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
    function Assert-NativeProviderContext {
    }
}
Describe 'Install-ProviderResource' -Tag 'PMU', 'PMUNativeAdapter' {
    BeforeEach {
        Mock Install-PSResource {}
        Mock Assert-NativeProviderContext {}
    }
    It 'updates only by native Update-Module with exact target and selected scope even for same-directory replacement' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Update-Module {}
        Install-ProviderResource $operation
        $operation.Reinstall = $true
        Install-ProviderResource $operation
        Should -Invoke Update-Module -Times 2 -ParameterFilter {
            $RequiredVersion -ceq '2.0.0-preview.2' -and $Scope -ceq 'CurrentUser' -and
            $AllowPrerelease -and $AcceptLicense -and -not $Force -and -not $Confirm
        }
    }
    It 'reports provider installation failures with a stable error id' {
        Mock Update-Module { throw 'disk failure' }
        { Install-ProviderResource (Initialize-PMUTestOperation $TestDrive) } | Should -Throw -ErrorId 'PMU.InstallationFailed'
    }
    It 'installs an opted-in unmanaged original via the exact provider install path' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        $operation.RepositoryName = 'ApprovedFeed'
        Mock Install-Module {}
        Mock Update-Module {}
        Install-ProviderResource $operation
        Should -Invoke Install-Module -Times 1 -ParameterFilter {
            $Name -ceq 'FixtureModule' -and $RequiredVersion -ceq '2.0.0-preview.2' -and
            $Repository -ceq 'ApprovedFeed' -and $Scope -ceq 'CurrentUser' -and
            $AllowPrerelease -and $AcceptLicense -and $Force -and -not $Confirm
        }
        Should -Invoke Update-Module -Times 0
    }
    It 'does not use the install path for a managed original even with consent' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        $path = Split-Path -Parent $operation.Plan.InstalledManifestPath
        [IO.File]::WriteAllText((Join-Path $path 'PSGetModuleInfo.xml'), 'present')
        Mock Install-Module {}
        Mock Update-Module {}
        Install-ProviderResource $operation
        Should -Invoke Update-Module -Times 1
        Should -Invoke Install-Module -Times 0
    }
    It 'installs a different-base unmanaged target without Force' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        $operation.Plan.TargetVersion = '3.0.0-preview1'
        $operation.Plan.TargetInstalledPath = Join-Path $TestDrive '3.0.0'
        Mock Install-Module {}
        Mock Update-Module {}
        Install-ProviderResource $operation
        Should -Invoke Install-Module -Times 1 -ParameterFilter { $RequiredVersion -ceq '3.0.0-preview1' -and -not $Force }
        Should -Invoke Update-Module -Times 0
    }
    It 'translates unmanaged provider install failures' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Consent.ReplaceUnmanagedInstallation = $true
        Mock Install-Module { throw 'disk failure' }
        { Install-ProviderResource $operation } | Should -Throw -ErrorId 'PMU.InstallationFailed'
    }
}
