BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ProviderContext' -Tag 'PMU' {
    It 'requires the explicitly qualified provider instead of substituting a newer loaded version' {
        Mock Get-Module { [pscustomobject]@{ Version = [version]'1.3.0' } }
        { Get-ProviderContext } | Should -Throw -ErrorId 'PMU.ProviderIncompatible'
    }
}
