BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-ExactTarget' -Tag 'PMU' {
    It 'never substitutes latest when the approved target disappears' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-RepositoryBinding {}
        Mock Find-ProviderResource { @() }
        { Assert-ExactTarget $operation } | Should -Throw -ErrorId 'PMU.PackageNotFound'
        Should -Invoke Find-ProviderResource -Times 1 -ParameterFilter { $Request.Version -eq '[2.0.0-preview.2]' }
    }
}
