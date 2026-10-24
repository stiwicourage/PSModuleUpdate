BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-UpdatePolicy' -Tag 'PMU' {
    It 'rejects explicit null scope instead of defaulting to another scope' {
        { ConvertTo-UpdatePolicy @{ Scope = $null } } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
    It 'rejects explicit null channel instead of defaulting to another channel' {
        { ConvertTo-UpdatePolicy @{ Channel = $null } } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
}
