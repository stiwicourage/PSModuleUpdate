function Read-NativeWorkerMessage {
    param([IO.TextReader]$Reader)
    while ($null -ne ($line = $Reader.ReadLine())) {
        if ($line.StartsWith('PMU_NATIVE:', [StringComparison]::Ordinal)) {
            return $line.Substring(11) | ConvertFrom-Json -ErrorAction Stop
        }
    }
    Write-PMUError 'PMU.RecoveryRequired' 'The native worker stopped without a complete protocol response. Pending state was preserved.'
}
