BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlanInstallationField' -Tag 'PMU' {
    Context 'Selected installation snapshot' {
        It 'retains the selected root and source' {
            $operation = Initialize-PMUTestOperation $TestDrive
            $fields = Get-PlanInstallationField $operation.TestContext
            $fields.DestinationRoot | Should -Be $operation.Plan.DestinationRoot
            $fields.RepositoryName | Should -Be 'OwnedFeed'
        }
    }
}
