function Install-ProviderResource {
    param([object]$Operation)
    Assert-NativeProviderContext $Operation
    try {
        if (Test-UnmanagedInstallation $Operation (Split-Path -Parent $Operation.Plan.InstalledManifestPath)) {
            $parameters = Get-NativeInstallParameter $Operation
            $null = PowerShellGet\Install-Module @parameters
        } else {
            $parameters = Get-NativeUpdateParameter $Operation
            $null = PowerShellGet\Update-Module @parameters
        }
    } catch {
        Write-ProviderError $_ 'PMU.InstallationFailed'
    }
}
