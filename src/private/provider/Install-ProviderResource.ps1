function Install-ProviderResource {
    param([object]$Operation)
    Assert-NativeProviderContext $Operation
    $parameters = Get-NativeUpdateParameter $Operation
    try {
        $null = PowerShellGet\Update-Module @parameters
    } catch {
        Write-ProviderError $_ 'PMU.InstallationFailed'
    }
}
