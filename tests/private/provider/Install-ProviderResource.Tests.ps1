BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Install-ProviderResource' -Tag 'PMU' {
    It 'uses Reinstall only for an explicitly verified collision' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Install-PSResource {}
        Install-ProviderResource $operation
        $operation.Reinstall = $true
        Install-ProviderResource $operation
        Should -Invoke Install-PSResource -Times 1 -ParameterFilter { $Reinstall -and $Version -eq '2.0.0-preview.2' }
        Should -Invoke Install-PSResource -Times 1 -ParameterFilter { -not $Reinstall -and $Scope -eq 'CurrentUser' -and $Version -eq '2.0.0-preview.2' }
    }
    It 'reports provider installation failures with a stable error id' {
        Mock Install-PSResource { throw 'disk failure' }
        { Install-ProviderResource (Initialize-PMUTestOperation $TestDrive) } | Should -Throw -ErrorId 'PMU.InstallationFailed'
    }
}
