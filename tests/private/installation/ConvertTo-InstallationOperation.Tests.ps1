BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-InstallationOperation' -Tag 'PMU' {
    It 'groups in-memory inputs without writing any persistent state' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.LockPath | Should -Be (Join-Path $operation.WorkRoot 'operation.lock')
        Test-Path $operation.WorkRoot | Should -BeFalse
    }
}
