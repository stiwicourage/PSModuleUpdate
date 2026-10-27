function ConvertTo-LinuxProcessStartIdentity {
    param([string]$Stat, [string]$BootStat, [string]$ClockTicksPerSecond)
    $started = ConvertFrom-LinuxProcessStat $Stat
    $boot = [regex]::Match($BootStat, '(?m)^btime ([0-9]+)\r?$')
    if (-not $boot.Success -or $ClockTicksPerSecond -notmatch '^[1-9][0-9]*$') {
        throw [IO.InvalidDataException]::new('Linux process clock metadata is invalid.')
    }
    $frequency = [long]::Parse($ClockTicksPerSecond, [Globalization.CultureInfo]::InvariantCulture)
    if ([TimeSpan]::TicksPerSecond % $frequency) {
        throw [IO.InvalidDataException]::new('Linux process clock ticks cannot be represented exactly.')
    }
    $unitTicks = [long]([TimeSpan]::TicksPerSecond / $frequency)
    # Prefix 1 distinguishes kernel-derived Unix-epoch ticks from legacy .NET UTC receipts.
    '1' + ([long]$boot.Groups[1].Value * [TimeSpan]::TicksPerSecond + $started * $unitTicks).ToString('D17', [Globalization.CultureInfo]::InvariantCulture)
}
