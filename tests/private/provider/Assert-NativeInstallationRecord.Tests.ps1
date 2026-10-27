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
}
