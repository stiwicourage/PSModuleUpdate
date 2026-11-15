BeforeAll {
    class PMUTestWindowsIdentity {
        static [object] $Current
        static [object] GetCurrent() { return [PMUTestWindowsIdentity]::Current }
    }
    if (-not $IsWindows) {
        # Substitute only the Windows-only API boundary before loading the real source.
        $script:identityTypes = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
        $script:originalIdentityType = $identityTypes::Get['Security.Principal.WindowsIdentity']
        $identityTypes::Add('Security.Principal.WindowsIdentity', [PMUTestWindowsIdentity])
        $script:typeCache = [psobject].Assembly.GetType('System.Management.Automation.Language.TypeCache').
            GetField('s_cache', [Reflection.BindingFlags]'Static,NonPublic').GetValue($null)
        $typeCache.Clear()
        # Get-Acl is absent on Unix; provide a fail-closed target for Pester's mock.
        $null = New-Item Function:Get-Acl -Value {
            [CmdletBinding()]
            param([string]$LiteralPath)
            throw "Unexpected unmocked ACL read: $LiteralPath"
        }
    }
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    if (-not $IsWindows) {
        # Reparse cached native calls, retaining canonical source extents for coverage.
        $source = (Resolve-Path "$PSScriptRoot/../../../src/private/locking/Get-WindowsDirectoryDescriptor.ps1").Path
        . ([Management.Automation.Language.Parser]::ParseFile($source, [ref]$null, [ref]$null).GetScriptBlock())
    }
}
AfterAll {
    if (-not $IsWindows) {
        $null = $identityTypes::Remove('Security.Principal.WindowsIdentity')
        if ($originalIdentityType) {
            $identityTypes::Add('Security.Principal.WindowsIdentity', $originalIdentityType)
        }
        $typeCache.Clear()
    }
}
Describe 'Get-WindowsDirectoryDescriptor' -Tag 'PMU', 'PMUCoverage' {
    BeforeEach {
        $identity = [pscustomobject]@{
            User = [pscustomobject]@{ Value = 'S-1-5-21-1234' }
            Disposed = $false
        }
        $identity | Add-Member ScriptMethod Dispose { $this.Disposed = $true }
        [PMUTestWindowsIdentity]::Current = $identity
    }
    Context 'Native Windows descriptor' {
        It 'reads current-user ACL metadata from a disposable directory' -Skip:(-not $IsWindows) {
            $descriptor = Get-WindowsDirectoryDescriptor $TestDrive
            $descriptor.Trusted | Should -Contain $descriptor.Owner
        }
    }

    It 'propagates ACL read failures after releasing the current Windows identity' {
        Mock Get-Acl {
            if (-not $IsWindows) {
                [PMUTestWindowsIdentity]::Current.Disposed | Should -BeTrue
            }
            throw [IO.IOException]::new('ACL read failed.')
        }
        { Get-WindowsDirectoryDescriptor $TestDrive } | Should -Throw -ExpectedMessage 'ACL read failed.'
        Should -Invoke Get-Acl -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $TestDrive -and $ErrorAction -eq 'Stop' }
    }
    It 'maps ACL owner and access decisions while retaining the trusted system identities' {
        $rules = @(
            [pscustomobject]@{ IdentityReference = @{ Value = 'S-1-5-18' }; AccessControlType = 'Allow'; FileSystemRights = [Security.AccessControl.FileSystemRights]::Write }
            [pscustomobject]@{ IdentityReference = @{ Value = 'S-1-5-32-545' }; AccessControlType = 'Deny'; FileSystemRights = [Security.AccessControl.FileSystemRights]::Read }
        )
        $acl = [pscustomobject]@{ Rules = $rules }
        $acl | Add-Member ScriptMethod GetOwner { [pscustomobject]@{ Value = 'S-1-5-18' } }
        $acl | Add-Member ScriptMethod GetAccessRules { $this.Rules }
        Mock Get-Acl { $acl }
        $descriptor = Get-WindowsDirectoryDescriptor $TestDrive
        $descriptor.Owner | Should -BeExactly 'S-1-5-18'
        $descriptor.Trusted | Should -Contain 'S-1-5-32-544'
        $descriptor.Access.Count | Should -Be 2
        $descriptor.Access[0].Identity | Should -BeExactly 'S-1-5-18'
        $descriptor.Access[0].Allowed | Should -BeTrue
        $descriptor.Access[0].CanWrite | Should -BeTrue
        $descriptor.Access[1].Identity | Should -BeExactly 'S-1-5-32-545'
        $descriptor.Access[1].Allowed | Should -BeFalse
        $descriptor.Access[1].CanWrite | Should -BeFalse
        Should -Invoke Get-Acl -Times 1 -Exactly -ParameterFilter { $LiteralPath -ceq $TestDrive -and $ErrorAction -eq 'Stop' }
    }
}
