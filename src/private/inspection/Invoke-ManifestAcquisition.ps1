function Invoke-ManifestAcquisition {
    param([object]$Operation)
    $module = @(Get-Module -Name PSModuleUpdate)
    if ($module.Count -ne 1) {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'Manifest acquisition requires the current built PMU module instance.'
    }
    $context = ConvertTo-ManifestWorkerContext $Operation $module[0].Path
    Invoke-ManifestWorkerProcess $Operation $context
}
