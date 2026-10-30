BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Assert-ExactTarget' -Tag 'PMU' {
    It 'never substitutes latest when the approved target disappears' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-RepositoryBinding {}
        Mock Find-ProviderResource { @() }
        { Assert-ExactTarget $operation } | Should -Throw -ErrorId 'PMU.PackageNotFound'
        Should -Invoke Find-ProviderResource -Times 1 -ParameterFilter { $Request.Version -eq '[2.0.0-preview.2]' }
    }
    It 'fails closed without retry or substitution for provider ID <ProviderId>' -Tag 'PMUPackageNotFound' -ForEach @(
        @{ ProviderId = 'PackageNotFound' }
        @{ ProviderId = 'PackageNotFound,Microsoft.PowerShell.PSResourceGet.Cmdlets.FindPSResource' }
    ) {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-RepositoryBinding {}
        Mock Find-PSResource { throw (Get-PMUTestProviderFailure $ProviderId) }
        { Assert-ExactTarget $operation } | Should -Throw -ErrorId 'PMU.PackageNotFound'
        Should -Invoke Find-PSResource -Times 1 -Exactly -ParameterFilter { $Version -eq '[2.0.0-preview.2]' -and $ErrorAction -eq 'Stop' }
    }
}
