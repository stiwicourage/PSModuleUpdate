function Get-LinuxRepositoryProcessStart {
    param([int]$ProcessId)
    try {
        $stat = [IO.File]::ReadAllText("/proc/$ProcessId/stat")
    } catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] {
        return $null
    }
    $frequency = & '/usr/bin/getconf' CLK_TCK
    if ($LASTEXITCODE -ne 0) {
        throw [IO.InvalidDataException]::new('Cannot read the Linux process clock frequency.')
    }
    ConvertTo-LinuxProcessStartIdentity $stat ([IO.File]::ReadAllText('/proc/stat')) $frequency
}
