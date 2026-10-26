BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ProviderMutationParameter' -Tag 'PMU' {
    It 'forwards exact target <Version> without range syntax and preserves consent' -ForEach @(
        @{ Version = '2.0.0' }
        @{ Version = '2.0.0-preview.2' }
        @{ Version = '0.1.1-preview01' }
    ) {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetVersion = $Version
        $parameters = Get-ProviderMutationParameter $operation
        $parameters.Version | Should -BeExactly $Version
        $parameters.Quiet | Should -BeTrue
        $parameters.Confirm | Should -BeFalse
        $parameters.ContainsKey('Reinstall') | Should -BeFalse
    }
    It 'forwards a credential only when the operation carries one' {
        $operation = Initialize-PMUTestOperation $TestDrive
        (Get-ProviderMutationParameter $operation).ContainsKey('Credential') | Should -BeFalse
        $operation.Credential = [pscredential]::new('user', [securestring]::new())
        (Get-ProviderMutationParameter $operation).Credential.UserName | Should -Be 'user'
    }
}
