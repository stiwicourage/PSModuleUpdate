BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-UpdatePolicy' -Tag 'PMU' {
    It 'applies the four exact defaults' {
        $policy = ConvertTo-UpdatePolicy @{}
        $policy.Channel | Should -Be 'Stable'
        $policy.Scope | Should -Be 'CurrentUser'
        $policy.ExpectedRepositoryUri | Should -BeNullOrEmpty
        $policy.VersionRange | Should -BeNullOrEmpty
    }
    It 'rejects unknown policy keys' {
        { ConvertTo-UpdatePolicy @{ Force = $true } } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
    It 'accepts explicit AllUsers and prerelease policy' {
        (ConvertTo-UpdatePolicy @{ Scope = 'AllUsers'; Channel = 'IncludePrerelease' }).Scope | Should -Be 'AllUsers'
    }
}
