# Get-NativeInstalledSource.Tests.ps1 covers valid identity and changed destination.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeInstallationRecord' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'refuses an unbindable native repository name' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $metadata = [pscustomobject]@{
            Name = $operation.Plan.ModuleName
            InstalledLocation = $TestDrive
            Repository = 'wildcard*'
            RepositorySourceLocation = $operation.Plan.RepositoryUri
        }
        { Assert-NativeInstallationRecord $metadata $operation $TestDrive } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'accepts case-insensitive provider module identity without rewriting its native spelling' {
        $metadata = [pscustomobject]@{
            Name = 'fIxTuReMoDuLe'
            InstalledLocation = $TestDrive
            Repository = 'LiteralFeed'
            RepositorySourceLocation = 'https://feed.invalid'
        }
        $operation = @{ Plan = @{ ModuleName = 'FixtureModule' } }
        $before = ConvertTo-Json $metadata -Compress
        @(Assert-NativeInstallationRecord $metadata $operation $TestDrive).Count | Should -Be 0
        ConvertTo-Json $metadata -Compress | Should -BeExactly $before
    }
}
