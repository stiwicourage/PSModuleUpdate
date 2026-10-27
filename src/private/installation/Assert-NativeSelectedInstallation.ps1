function Assert-NativeSelectedInstallation {
    param([object]$Context)
    $operation = $Context.Operation
    Assert-NativeProviderContext $operation
    if ((Test-InstalledPlanState $operation) -ne $Context.AlreadyInstalled) {
        Write-PMUError 'PMU.InstalledStateChanged' 'The selected installation changed during handoff.'
    }
    Assert-NativeInstallationSnapshot $Context
    if ($Context.AlreadyInstalled) {
        return
    }
    $parameters = Get-NativeUpdateParameter $operation
    $native = @(PowerShellGet\Get-InstalledModule -Name $operation.Plan.ModuleName -AllowPrerelease:([bool]$parameters['AllowPrerelease']) -ErrorAction Stop)
    Assert-NativeCandidate $operation ($native | Select-Object -First 1)
}
