# Get-NativeUpdateParameter.Tests.ps1 owns the complete approved-boundary table.
# This predicate must never turn a newer numeric target into a broad ceiling.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-SameBaseStablePromotion' -Tag 'PMU', 'PMUNativeAdapter' {
    It 'does not broaden an exact stable target above the selected numeric base' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetVersion = '3.0.0'
        $operation.Plan.TargetNumericVersion = '3.0.0'
        $operation.Plan.TargetIsPrerelease = $false
        Test-SameBaseStablePromotion $operation.Plan | Should -BeFalse
    }
}
