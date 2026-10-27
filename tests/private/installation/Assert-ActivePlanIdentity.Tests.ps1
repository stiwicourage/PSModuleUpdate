BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-ActivePlanIdentity' -Tag 'PMU' {
    It 'accepts an unloaded installed reference even when a different copy is loaded' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $script:otherLoaded = [pscustomobject]@{
            ManifestPath = "$TestDrive/other/FixtureModule.psd1"
            Version = @{ FullVersion = '1.0.0' }
        }
        $operation.Plan.ActivePath = $otherLoaded.ManifestPath
        $operation.Plan.ActiveVersion = '1.0.0'
        Mock Get-ActiveModuleIdentity { $script:otherLoaded }
        { Assert-ActivePlanIdentity $operation } | Should -Not -Throw
    }
    It 'retains resolution-change protection when the supplied reference really was loaded' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Record.WasLoaded = $true
        $operation.Plan.ActivePath = $operation.Record.ReferencePath
        $operation.Plan.ActiveVersion = '2.0.0-preview.1'
        Mock Get-ActiveModuleIdentity { [pscustomobject]@{
                ManifestPath = 'different.psd1'
                Version = @{ FullVersion = '1.0.0' }
            } }
        { Assert-ActivePlanIdentity $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
    It 'rejects an active path changed independently from the approved plan' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.ActivePath = "$TestDrive/elsewhere.psd1"
        { Assert-ActivePlanIdentity $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
    It 'retains the supplied target reference path guard when no module is loaded' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Record.ReferencePath = "$TestDrive/changed-reference.psd1"
        { Assert-ActivePlanIdentity $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
}
