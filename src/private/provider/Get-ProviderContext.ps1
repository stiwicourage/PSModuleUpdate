function Get-ProviderContext {
    param()
    $provider = Get-Module Microsoft.PowerShell.PSResourceGet
    if (-not $provider) {
        try { $provider = Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0 -PassThru -ErrorAction Stop }
        catch { Write-PMUError 'PMU.ProviderUnavailable' 'PSResourceGet 1.2.0 must be available; PMU does not install it.' }
    }
    if ($provider.Version -ne [version]'1.2.0') {
        Write-PMUError 'PMU.ProviderIncompatible' 'Only the qualified PSResourceGet 1.2.0 baseline is enabled.'
    }
    $provider
}
