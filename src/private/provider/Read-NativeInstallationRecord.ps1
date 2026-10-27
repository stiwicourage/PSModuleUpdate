function Read-NativeInstallationRecord {
    param([string]$SelectedPath)
    $path = Join-Path $SelectedPath 'PSGetModuleInfo.xml'
    if (-not (Test-Path -LiteralPath $path)) {
        Write-PMUError 'PMU.UnsupportedInstallation' 'The selected installation has no native provider metadata.'
    }
    try {
        Import-Clixml -LiteralPath $path -ErrorAction Stop
    } catch {
        Write-PMUError 'PMU.UnsupportedInstallation' 'The selected native installation metadata is unreadable.'
    }
}
