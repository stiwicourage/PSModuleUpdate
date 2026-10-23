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
        Should -Invoke Install-PSResource -Times 1 -ParameterFilter { $Reinstall }
        Should -Invoke Install-PSResource -Times 1 -ParameterFilter { -not $Reinstall -and $Scope -eq 'CurrentUser' }
    }
}
