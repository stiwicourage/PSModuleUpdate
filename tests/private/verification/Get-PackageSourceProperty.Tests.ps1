BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PackageSourceProperty' -Tag 'PMU' {
    Context 'Optional independently available metadata' {
        It 'reports corrupt metadata rather than treating it as valid provenance' {
            [IO.File]::WriteAllText("$TestDrive/PSGetModuleInfo.xml", 'corrupt')
            { Get-PackageSourceProperty $TestDrive } | Should -Throw -ErrorId 'PMU.VerificationFailed'
        }
    }
}
