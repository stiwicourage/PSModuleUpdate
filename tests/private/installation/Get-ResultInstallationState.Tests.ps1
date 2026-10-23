BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ResultInstallationState' -Tag 'PMU' {
    Context 'Non-mutating result' {
        It 'does not claim a planned target is already installed for WhatIf' {
            $operation = Initialize-PMUTestOperation $TestDrive
            (Get-ResultInstallationState $operation.Plan 'NotPerformed').Version | Should -Be '2.0.0-preview.1'
        }
    }
}
