BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeRecordField' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'fails closed on incomplete provider-specific metadata instead of synthesizing an installation' {
        { Assert-NativeRecordField ([pscustomobject]@{ Name = 'FixtureModule' }) } |
            Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects an empty required native metadata value in <Field>' -ForEach @(
        @{ Field = 'Name' }
        @{ Field = 'Repository' }
        @{ Field = 'RepositorySourceLocation' }
        @{ Field = 'InstalledLocation' }
    ) {
        $metadata = [pscustomobject]@{
            Name = 'FixtureModule'
            Repository = 'LiteralFeed'
            RepositorySourceLocation = 'https://feed.invalid'
            InstalledLocation = $TestDrive
        }
        $metadata.$Field = ''
        { Assert-NativeRecordField $metadata } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
        $metadata.$Field | Should -BeExactly ''
    }
}
