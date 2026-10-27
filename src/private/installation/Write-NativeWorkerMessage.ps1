function Write-NativeWorkerMessage {
    param([object]$Message)
    [Console]::Out.WriteLine('PMU_NATIVE:' + (ConvertTo-Json $Message -Depth 6 -Compress))
    [Console]::Out.Flush()
}
