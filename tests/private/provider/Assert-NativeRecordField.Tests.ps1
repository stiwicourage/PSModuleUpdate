BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeRecordField' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'fails closed on incomplete provider-specific metadata instead of synthesizing an installation' {
        { Assert-NativeRecordField ([pscustomobject]@{ Name = 'FixtureModule' }) } |
            Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
}
