function Invoke-NativeWorkerStart {
    param(
        [object]$Operation,
        [object]$Context
    )

    $process = [Diagnostics.Process]::Start((Initialize-NativeWorkerStartInfo $Context))
    $worker = [pscustomobject]@{
        Process = $process
        Errors = $process.StandardError.ReadToEndAsync()
        ExitCode = $null
    }
    try {
        $payload = ConvertTo-NativeWorkerPayload $Context
        $process.StandardInput.AutoFlush = $true
        $process.StandardInput.WriteLine($payload)
        $worker
    } catch {
        Complete-NativeWorkerLease $Operation $worker
        Write-ProviderError $_ 'PMU.InstallationFailed'
    }
}
