BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-WindowsAccessRule' -Tag 'PMU' {
    Context 'Trusted scope writers' {
        It 'allows read-only access for unrelated accounts without granting mutation rights' {
            { Assert-WindowsAccessRule @{ Allowed = $true; CanWrite = $false; Identity = 'reader' } @('owner') } | Should -Not -Throw
        }
    }
}
