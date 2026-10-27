# Get-NativeInstalledSource.Tests.ps1 verifies normal and missing-file reads
# without rewriting metadata; unreadable XML is separately characterized here.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Read-NativeInstallationRecord' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'withholds malformed provider diagnostics and fails as unsupported installation' {
        [IO.File]::WriteAllText((Join-Path $TestDrive 'PSGetModuleInfo.xml'), 'not XML')
        { Read-NativeInstallationRecord $TestDrive } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
}
