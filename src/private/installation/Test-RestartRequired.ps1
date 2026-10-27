function Test-RestartRequired {
    param(
        [object]$Plan,
        [string]$Outcome
    )

    $loaded = @(Get-Module -Name $Plan.ModuleName | Where-Object Guid -EQ $Plan.ModuleGuid)
    if (-not $loaded.Count) {
        return $false
    }
    $target = [IO.Path]::GetFullPath($Plan.TargetInstalledPath)
    $replacedLoaded = @($loaded | Where-Object { [IO.Path]::GetFullPath($_.ModuleBase) -eq $target }).Count -gt 0
    if ($Outcome -eq 'Installed' -and $replacedLoaded) {
        return $true
    }
    $behindTarget = @($loaded | Where-Object { (Compare-CompleteModuleVersion $Plan.TargetVersion (Get-ActiveModuleVersion $_).FullVersion) -gt 0 })
    $behindTarget.Count -gt 0
}
