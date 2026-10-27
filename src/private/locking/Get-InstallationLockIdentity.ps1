function Get-InstallationLockIdentity {
    param([object]$Plan)
    $identity = "$($Plan.ModuleName.ToLowerInvariant())|$($Plan.Scope)|$($Plan.DestinationRoot)"
    if ($IsWindows -or $IsMacOS) {
        $identity = $identity.ToLowerInvariant()
    }
    $hash = [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($identity))
    [Convert]::ToHexString($hash).ToLowerInvariant()
}
