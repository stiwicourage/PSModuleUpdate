BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-ManifestInspectionOperation' -Tag 'PMU', 'PMUTargetManifest' {
    It 'uses a unique user-owned workspace even when inspecting an AllUsers plan' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.Scope = 'AllUsers'
        $snapshot = ConvertTo-Json $operation.Plan -Depth 12
        $result = ConvertTo-ManifestInspectionOperation $operation
        $result.WorkRoot | Should -BeExactly (Join-Path $result.DataRoot "inspection-$($result.Journal.TransactionId)")
        $result.StageRoot | Should -BeExactly (Join-Path $result.WorkRoot 'stage')
        (ConvertTo-Json $operation.Plan -Depth 12) | Should -BeExactly $snapshot
        Test-Path $result.WorkRoot | Should -BeFalse
        Should -Invoke Resolve-PMUDataRoot -ParameterFilter {
            $Scope -eq 'CurrentUser'
        }
    }
}
