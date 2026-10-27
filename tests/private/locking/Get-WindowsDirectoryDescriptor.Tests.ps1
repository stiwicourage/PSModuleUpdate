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
    Context 'Native Windows descriptor' {
        It 'reads current-user ACL metadata from a disposable directory' -Skip:(-not $IsWindows) {
            $descriptor = Get-WindowsDirectoryDescriptor $TestDrive
            $descriptor.Trusted | Should -Contain $descriptor.Owner
        }
    }

    It 'propagates ACL read failures after releasing the current Windows identity' {
        $identity = [pscustomobject]@{
            User = [pscustomobject]@{ Value = 'S-1-5-21-1234' }
            Disposed = $false
        }
        $identity | Add-Member ScriptMethod Dispose { $this.Disposed = $true }
        [PMUTestWindowsIdentity]::Current = $identity
        Mock Get-Acl {
            if (-not $IsWindows) {
                [PMUTestWindowsIdentity]::Current.Disposed | Should -BeTrue
            }
            throw [IO.IOException]::new('ACL read failed.')
        }
        { Get-WindowsDirectoryDescriptor $TestDrive } | Should -Throw -ExpectedMessage 'ACL read failed.'
        Should -Invoke Get-Acl -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $TestDrive -and $ErrorAction -eq 'Stop' }
    }
}
