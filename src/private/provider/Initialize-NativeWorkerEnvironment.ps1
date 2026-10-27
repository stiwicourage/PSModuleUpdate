function Initialize-NativeWorkerEnvironment {
    param(
        [Diagnostics.ProcessStartInfo]$Start,
        [string]$Root
    )

    $paths = Get-NativeWorkerDirectoryMap
    Initialize-ControlledDirectory $Root
    foreach ($key in $paths.Keys) {
        $path = Join-Path $Root $paths[$key]
        Initialize-ControlledDirectory $path
        $Start.Environment[$key] = $path
    }
    $Start.WorkingDirectory = $Root
}
