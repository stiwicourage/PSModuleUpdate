BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlanDecisionField' -Tag 'PMU' {
    Context 'Selection decision snapshot' {
        It 'retains explicit prerequisites without granting consent' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $fields = Get-PlanDecisionField $operation.TestContext
            $fields.Disposition | Should -Be 'UpdateAvailable'
            $fields.RequiresRepositoryTrust | Should -BeFalse
        }
    }
}
