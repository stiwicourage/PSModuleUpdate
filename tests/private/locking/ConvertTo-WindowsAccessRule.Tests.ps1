BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-WindowsAccessRule' -Tag 'PMU' {
    Context 'Windows write rights' {
        It 'distinguishes read-only and mutation permissions' {
            $rule = @{ IdentityReference = @{ Value = 'fixture-sid' }; AccessControlType = 'Allow'; FileSystemRights = [Security.AccessControl.FileSystemRights]::Read }
            (ConvertTo-WindowsAccessRule $rule).CanWrite | Should -BeFalse
            $rule.FileSystemRights = [Security.AccessControl.FileSystemRights]::Modify
            (ConvertTo-WindowsAccessRule $rule).CanWrite | Should -BeTrue
        }
    }
}
