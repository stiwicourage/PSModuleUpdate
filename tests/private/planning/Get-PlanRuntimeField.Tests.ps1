BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlanRuntimeField' -Tag 'PMU' {
    Context 'Active runtime snapshot' {
        It 'preserves reference identity independently from absent actual active fields' {
            $operation = Initialize-PMUTestOperation $TestDrive
            (Get-PlanRuntimeField $operation.TestContext).ActiveVersion | Should -BeNullOrEmpty
            (Get-PlanRuntimeField $operation.TestContext).ModuleGuid | Should -Be $operation.Record.Module.Guid
        }
    }
}
