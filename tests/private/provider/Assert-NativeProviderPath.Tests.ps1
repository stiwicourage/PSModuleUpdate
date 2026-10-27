# Assert-NativeProviderContext.Tests.ps1 owns the positive/escaped-store and
# changed-destination cases across the runtime snapshot and path validator.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeProviderPath' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'rejects an unowned native store even if its pathname is superficially similar' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $operation | Add-Member NativeContext ([pscustomobject]@{ Root = "$TestDrive/native" })
        $paths = [pscustomobject]@{ Store = "$TestDrive/native-neighbor/repos.xml" }
        { Assert-NativeProviderPath $operation $paths } | Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'
    }
}
