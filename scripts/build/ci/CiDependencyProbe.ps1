[CmdletBinding()]
param([Parameter(Mandatory)][string]$ModuleRoot)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'CiDependencyRoot.ps1')

function Assert-CiDependencyOrigin {
    param([Parameter(Mandatory)][string]$ModuleRoot)

    foreach ($module in Get-Module) {
        $owned = $module.ModuleBase.StartsWith($ModuleRoot + [IO.Path]::DirectorySeparatorChar)
        $builtin = $module.ModuleBase -eq $PSHOME -or $module.ModuleBase.StartsWith($PSHOME + [IO.Path]::DirectorySeparatorChar)
        if (-not ($owned -or $builtin)) {
            throw "Dependency resolved outside isolation: $($module.Name)."
        }
    }
}

function Invoke-CiDependencyProbe {
    param([Parameter(Mandatory)][string]$ModuleRoot)

    $savedPath = $env:PSModulePath
    $env:PSModulePath = Get-CiIsolatedModulePath -ModuleRoot $ModuleRoot
    try {
        Import-Module Pester -RequiredVersion 5.7.1 -ErrorAction Stop
        Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0 -ErrorAction Stop
        Import-Module NovaModuleTools -ErrorAction Stop
        Assert-CiDependencyOrigin -ModuleRoot $ModuleRoot
    } finally {
        $env:PSModulePath = $savedPath
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-CiDependencyProbe -ModuleRoot $ModuleRoot
}
