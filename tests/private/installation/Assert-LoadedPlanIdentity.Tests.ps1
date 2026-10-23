BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-LoadedPlanIdentity' -Tag 'PMUActualActive' {
    Context 'Live loaded-state staleness' {
        It 'rejects a different active path rather than altering the approved snapshot' {
            $operation = Initialize-PMUTestOperation $TestDrive
            Mock Get-ActiveModuleIdentity { [pscustomobject]@{ ManifestPath = '/different/module.psd1'; Version = @{ FullVersion = '9.0.0' } } }
            { Assert-LoadedPlanIdentity $operation } | Should -Throw -ErrorId 'PMU.PlanStale*'
        }
    }
}
