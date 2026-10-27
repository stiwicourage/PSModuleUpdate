function ConvertFrom-LinuxProcessStat {
    param([string]$Stat)
    $fields = [regex]::Match($Stat, '(?s)^[0-9]+ \(.*\) (.+)$').Groups[1].Value -split ' '
    if ($fields.Count -lt 20) {
        throw [IO.InvalidDataException]::new('Linux process start metadata is incomplete.')
    }
    [long]::Parse($fields[19], [Globalization.CultureInfo]::InvariantCulture)
}
