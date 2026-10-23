BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-ActivePlanField' -Tag 'PMUActualActive' {
    Context 'Absent actual session state' {
        It 'does not substitute the reference version or selected-scope path' {
            $fields = Get-ActivePlanField ([pscustomobject]@{ Active = $null })
            $fields.Version | Should -BeNullOrEmpty
            $fields.Path | Should -BeNullOrEmpty
            $fields.Scope | Should -BeNullOrEmpty
        }
    }
}
