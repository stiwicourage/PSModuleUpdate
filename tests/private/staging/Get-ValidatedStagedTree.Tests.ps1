BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-ValidatedStagedTree' -Tag 'PMU', 'PMUTargetManifest' {
    It 'returns the validated exact package inventory without importing its throwing root module' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $null = Initialize-PMUTestPackage $operation.StageRoot $operation.Plan.TargetVersion
        $tree = @(Get-ValidatedStagedTree $operation)
        $tree.Count | Should -Be 2
        @(Get-Module FixtureModule).Count | Should -Be 0
    }
}
