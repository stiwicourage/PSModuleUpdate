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
}
