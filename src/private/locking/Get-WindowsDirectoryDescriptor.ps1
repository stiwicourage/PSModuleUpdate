function Get-WindowsDirectoryDescriptor {
    param([string]$Path)
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try { $trusted = @($identity.User.Value, 'S-1-5-18', 'S-1-5-32-544', 'S-1-3-0') }
    finally { $identity.Dispose() }
    $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    $rules = $acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])
    [pscustomobject]@{
        Owner = $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value
        Trusted = $trusted
        Access = @($rules | ForEach-Object { ConvertTo-WindowsAccessRule $_ })
    }
}
