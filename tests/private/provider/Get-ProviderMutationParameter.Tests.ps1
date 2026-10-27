BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-ProviderMutationParameter' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'keeps mutation maps independent and explicitly preserves declined consent and credential identity' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Consent.AcceptLicense = $false
        $operation.Credential = [pscredential]::new('user', [securestring]::new())
        $first = Get-ProviderMutationParameter $operation
        $second = Get-ProviderMutationParameter $operation

        $first | Should -BeOfType [hashtable]
        $first.AcceptLicense | Should -BeOfType [bool]
        $first.AcceptLicense | Should -BeFalse
        [object]::ReferenceEquals($first.Credential, $operation.Credential) | Should -BeTrue
        $first.RequiredVersion = 'CallerChanged'
        $second.RequiredVersion | Should -BeExactly $operation.Plan.TargetVersion
        $second.ContainsKey('ErrorVariable') | Should -BeFalse
    }
    It 'forwards exact target <Version> without range syntax and preserves consent' -ForEach @(
        @{ Version = '2.0.0' }
        @{ Version = '2.0.0-preview.2' }
        @{ Version = '0.1.1-preview01' }
        @{ Version = '4.0.0.7' }
    ) {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetVersion = $Version
        $parameters = Get-ProviderMutationParameter $operation
        $parameters.RequiredVersion | Should -BeExactly $Version
        $parameters.AllowPrerelease | Should -Be $operation.Plan.TargetIsPrerelease
        $parameters.AcceptLicense | Should -BeTrue
        $parameters.Confirm | Should -BeFalse
        $parameters.ContainsKey('Reinstall') | Should -BeFalse
        $parameters.ContainsKey('Force') | Should -BeFalse
        $parameters.ContainsKey('TrustRepository') | Should -BeFalse
    }
    It 'forwards a credential only when the operation carries one' {
        $operation = Initialize-PMUTestOperation $TestDrive
        (Get-ProviderMutationParameter $operation).ContainsKey('Credential') | Should -BeFalse
        $operation.Credential = [pscredential]::new('user', [securestring]::new())
        (Get-ProviderMutationParameter $operation).Credential.UserName | Should -Be 'user'
    }
}
