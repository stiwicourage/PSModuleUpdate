function Initialize-ControlledDirectory {
    param([string]$Path)
    $safe = Assert-SafePath $Path
    if ($IsWindows) {
        Initialize-WindowsControlledDirectory $safe
        return
    }
    $mode = [IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute
    $null = [IO.Directory]::CreateDirectory($safe, $mode)
    Assert-UnixDirectoryOwner $safe
    $unsafe = [IO.UnixFileMode]::GroupWrite -bor [IO.UnixFileMode]::OtherWrite
    if ([IO.File]::GetUnixFileMode($safe) -band $unsafe) {
        Write-PMUError 'PMU.PermissionDenied' 'PMU data directories must not be writable by group or other users.'
    }
}
