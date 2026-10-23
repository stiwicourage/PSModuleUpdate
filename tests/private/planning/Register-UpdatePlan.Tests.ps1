BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Register-UpdatePlan' -Tag 'PMU' {
    It 'registers the exact object identity and a non-secret immutable snapshot' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $record = Test-UpdatePlan $operation.Plan
        $record.Snapshot | Should -Be (ConvertTo-Json $operation.Plan -Depth 12 -Compress)
        $record.InstalledTree.Count | Should -BeGreaterThan 0
    }
}
