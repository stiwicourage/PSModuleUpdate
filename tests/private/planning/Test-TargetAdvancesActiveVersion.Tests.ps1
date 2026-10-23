BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-TargetAdvancesActiveVersion' -Tag 'PMUActualActive' {
    Context 'Only actual loaded state constrains active downgrade checks' {
        It 'permits comparison against installed state alone when no module is loaded' {
            Test-TargetAdvancesActiveVersion '1.0.0' $null | Should -BeTrue
            Test-TargetAdvancesActiveVersion '1.0.0' ([pscustomobject]@{ Version = @{ FullVersion = '2.0.0' } }) | Should -BeFalse
        }
    }
}
