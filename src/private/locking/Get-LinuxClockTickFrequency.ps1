function Get-LinuxClockTickFrequency {
    param([string]$CommandPath = '/usr/bin/getconf')
    $frequency = & $CommandPath CLK_TCK
    if ($LASTEXITCODE -ne 0) {
        throw [IO.InvalidDataException]::new('Cannot read the Linux process clock frequency.')
    }
    $frequency
}
