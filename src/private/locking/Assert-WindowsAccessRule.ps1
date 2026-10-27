function Assert-WindowsAccessRule {
    param(
        [object]$Rule,
        [string[]]$Trusted
    )

    if (-not $Rule.Allowed) {
        return
    }
    if (-not $Rule.CanWrite) {
        return
    }
    if ($Rule.Identity -notin $Trusted) {
        Write-PMUError 'PMU.PermissionDenied' 'The PMU data directory grants write access to an unrelated account or group.'
    }
}
