BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Test-UpdatePlan' -Tag 'PMU' {
    It 'rejects serialized copies even when every public field matches' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $copy = $operation.Plan | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        { Test-UpdatePlan $copy } | Should -Throw -ErrorId 'PMU.InvalidPlan'
    }
}
