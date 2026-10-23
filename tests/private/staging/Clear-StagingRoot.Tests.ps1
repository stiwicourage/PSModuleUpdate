BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Clear-StagingRoot' -Tag 'PMU' {
    It 'rejects an operation whose staging path was substituted outside its workspace' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.StageRoot = $TestDrive
        { Clear-StagingRoot $operation } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
        Test-Path $operation.Plan.InstalledManifestPath | Should -BeTrue
    }
}
