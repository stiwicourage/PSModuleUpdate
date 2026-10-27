BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-WindowsDirectoryDescriptor' -Tag 'PMU', 'PMUSafety' {
    Context 'Scope data ACL' {
        It 'accepts a trusted owner with unrelated read-only access' {
            $descriptor = @{
                Owner = 'owner'
                Trusted = @('owner')
                Access = @(@{
                        Identity = 'reader'
                        CanWrite = $false
                        Allowed = $true
                    })
            }
            { Assert-WindowsDirectoryDescriptor $descriptor } | Should -Not -Throw
        }
        It 'rejects broadly writable Windows state even when its owner is trusted' {
            $descriptor = @{
                Owner = 'owner'
                Trusted = @('owner')
                Access = @(@{
                        Identity = 'everyone'
                        CanWrite = $true
                        Allowed = $true
                    })
            }
            { Assert-WindowsDirectoryDescriptor $descriptor } | Should -Throw -ErrorId 'PMU.PermissionDenied'
        }
        It 'rejects an unrelated owner even when write ACLs appear private' {
            $descriptor = @{
                Owner = 'untrusted'
                Trusted = @('owner')
                Access = @()
            }
            { Assert-WindowsDirectoryDescriptor $descriptor } | Should -Throw -ErrorId 'PMU.PermissionDenied'
        }
    }
}
