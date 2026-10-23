BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-UnixDirectoryOwner' -Tag 'PMU', 'PMUSafety' {
    Context 'Data-directory ownership' {
        It 'accepts a directory owned by the current account' {
            Mock Get-Item { [pscustomobject]@{ User = [Environment]::UserName } }
            { Assert-UnixDirectoryOwner $TestDrive } | Should -Not -Throw
        }
        It 'rejects a private-mode directory owned by another account' {
            Mock Get-Item { [pscustomobject]@{ User = 'untrusted-fixture-owner' } }
            { Assert-UnixDirectoryOwner $TestDrive } | Should -Throw -ErrorId 'PMU.PermissionDenied'
        }
        It 'fails closed when the platform cannot expose owner metadata' {
            Mock Get-Item { [pscustomobject]@{} }
            { Assert-UnixDirectoryOwner $TestDrive } | Should -Throw -ErrorId 'PMU.PermissionDenied'
        }
    }
}
