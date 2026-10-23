function ConvertTo-WindowsAccessRule {
    param([object]$Rule)
    $write = [Security.AccessControl.FileSystemRights]::Write -bor [Security.AccessControl.FileSystemRights]::Delete -bor [Security.AccessControl.FileSystemRights]::ChangePermissions -bor [Security.AccessControl.FileSystemRights]::TakeOwnership
    [pscustomobject]@{
        Identity = $Rule.IdentityReference.Value
        Allowed = $Rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow
        CanWrite = [bool]($Rule.FileSystemRights -band $write)
    }
}
