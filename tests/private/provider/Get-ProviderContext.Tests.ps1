BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ProviderContext' -Tag 'PMU', 'PMUCoverage' {
    It 'requires the explicitly qualified provider instead of substituting a newer loaded version' {
        Mock Get-Module { [pscustomobject]@{ Version = [version]'1.3.0' } }
        { Get-ProviderContext } | Should -Throw -ErrorId 'PMU.ProviderIncompatible'
    }

    It 'imports and returns the qualified provider when it is not already loaded' {
        Mock Get-Module {}
        $script:provider = [pscustomobject]@{ Version = [version]'1.2.0' }
        Mock Import-Module { $script:provider }
        Get-ProviderContext | Should -Be $script:provider
        Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and
            $RequiredVersion -eq [version]'1.2.0' -and $PassThru -and $ErrorAction -eq 'Stop'
        }
    }

    It 'reports an unavailable qualified provider without installing a replacement' {
        Mock Get-Module {}
        Mock Import-Module { throw 'Provider is not installed.' }
        { Get-ProviderContext } |
            Should -Throw -ErrorId 'PMU.ProviderUnavailable' -ExpectedMessage 'PSResourceGet 1.2.0 must be available; PMU does not install it.'
        Should -Invoke Import-Module -Times 1 -Exactly
    }
}
