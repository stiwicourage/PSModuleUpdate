function ConvertTo-UpdatePolicy {
    param([hashtable]$Policy = @{})
    $resolved = @{
        Channel = 'Stable'
        Scope = 'CurrentUser'
        ExpectedRepositoryUri = $null
        VersionRange = $null
    }
    foreach ($key in $Policy.Keys) {
        if (-not $resolved.ContainsKey($key)) {
            Write-PMUError 'PMU.InvalidRequest' 'Unknown policy field.'
        }
        $resolved[$key] = $Policy[$key]
    }
    Assert-UpdatePolicy $resolved
    $resolved
}
