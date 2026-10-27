function Get-NativeProviderPath {
    $provider = @(Get-Module -Name PowerShellGet)
    if ($provider.Count -ne 1 -or $provider[0].Version -ne [version]'2.2.5') {
        Write-PMUError 'PMU.UnsupportedProviderBehavior' 'The qualified native provider is not loaded.'
    }
    & $provider[0] {
        [pscustomobject]@{
            Store = $script:PSGetModuleSourcesFilePath
            Settings = $script:PSGetSettingsFilePath
            Config = $script:PSGetProgramDataPath
            Temporary = [IO.Path]::GetTempPath()
            CurrentUser = $script:PSGetPath.CurrentUserModules
            AllUsers = $script:PSGetPath.AllUsersModules
        }
    }
}
