BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-DeclinedUpdateResult' -Tag 'PMU' {
    It 'distinguishes cancellation from WhatIf without mutation' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $WhatIfPreference = $false
        (ConvertTo-DeclinedUpdateResult $operation.Plan).Outcome | Should -Be 'Cancelled'
        $WhatIfPreference = $true
        (ConvertTo-DeclinedUpdateResult $operation.Plan).Outcome | Should -Be 'WhatIf'
        Test-Path $operation.WorkRoot | Should -BeFalse
    }
}
