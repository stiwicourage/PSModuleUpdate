BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-RepositoryRegistration' -Tag 'PMUUriBridge' {
    Context 'Exact optional name lookup' {
        It 'returns absence without requesting a provider error for a missing name' {
            Mock Get-PSResourceRepository { [pscustomobject]@{ Name = 'ExistingConsumer' } }
            @(Get-RepositoryRegistration 'MissingNonce').Count | Should -Be 0
            Should -Invoke Get-PSResourceRepository -Times 1 -ParameterFilter { -not $Name }
        }
    }
}
