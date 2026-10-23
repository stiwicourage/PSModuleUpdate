function Assert-UnixDirectoryOwner {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $owner = $item.PSObject.Properties['User']
    if (-not $owner) { Write-PMUError 'PMU.PermissionDenied' 'The data-directory owner cannot be verified on this platform.' }
    if ($owner.Value -cnotin @([Environment]::UserName, 'root')) {
        Write-PMUError 'PMU.PermissionDenied' 'The PMU data directory is owned by an unrelated account.'
    }
}
