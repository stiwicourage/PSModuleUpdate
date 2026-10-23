function Resolve-ModuleInstallationRoot {
    param([ValidateSet('CurrentUser', 'AllUsers')][string]$Scope)
    if ($IsWindows) {
        if ($Scope -eq 'AllUsers') { return Assert-SafePath (Join-Path $env:ProgramFiles 'PowerShell/Modules') }
        return Assert-SafePath (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell/Modules')
    }
    if ($Scope -eq 'AllUsers') { return Assert-SafePath '/usr/local/share/powershell/Modules' }
    Assert-SafePath (Join-Path $HOME '.local/share/powershell/Modules')
}
