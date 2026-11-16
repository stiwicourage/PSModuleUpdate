function Get-LinuxRepositoryProcessStart {
    param(
        [int]$ProcessId,
        [string]$ProcRoot = '/proc'
    )
    try {
        $stat = [IO.File]::ReadAllText([IO.Path]::Combine($ProcRoot, "$ProcessId", 'stat'))
    } catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] {
        return $null
    }
    $frequency = Get-LinuxClockTickFrequency
    ConvertTo-LinuxProcessStartIdentity $stat ([IO.File]::ReadAllText([IO.Path]::Combine($ProcRoot, 'stat'))) $frequency
}
