BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlanTargetField' -Tag 'PMU' {
    Context 'Exact target snapshot' {
        It 'retains complete and numeric target identity separately' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $fields = Get-PlanTargetField $operation.TestContext
            $fields.TargetVersion | Should -Be '2.0.0-preview.2'
            $fields.TargetNumericVersion | Should -Be '2.0.0'
        }
    }
}
