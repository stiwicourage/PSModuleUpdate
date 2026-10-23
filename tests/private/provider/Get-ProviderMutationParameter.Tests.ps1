BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ProviderMutationParameter' -Tag 'PMU' {
    It 'binds an exact target, quiet operation and explicit consent without reinstall' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $parameters = Get-ProviderMutationParameter $operation
        $parameters.Version | Should -Be '[2.0.0-preview.2]'
        $parameters.Quiet | Should -BeTrue
        $parameters.Confirm | Should -BeFalse
        $parameters.ContainsKey('Reinstall') | Should -BeFalse
    }
}
