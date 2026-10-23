[CmdletBinding()]
param(
    [string[]]$Name = @('Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet', 'Microsoft.PowerShell.PlatyPS'),
    [string]$ModuleRoot = (Join-Path ([IO.Path]::GetTempPath()) "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))")
)

. (Join-Path $PSScriptRoot 'CiDependencyRoot.ps1')

$script:PinnedVersion = @{
    Pester = '5.7.1'
    'Microsoft.PowerShell.PSResourceGet' = '1.2.0'
}

function Get-CiModuleInstallParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$ModuleRoot
    )

    $parameter = @{
        Name = $Name
        Repository = 'PSGallery'
        Path = $ModuleRoot
        Force = $true
        ErrorAction = 'Stop'
    }
    if ($script:PinnedVersion.ContainsKey($Name)) {
        $parameter['RequiredVersion'] = $script:PinnedVersion[$Name]
    }

    return $parameter
}

function Save-CiPowerShellModule {
    param([string[]]$Name, [Parameter(Mandatory)][string]$ModuleRoot)

    $owner = New-CiDependencyRoot -Path $ModuleRoot
    try {
        foreach ($moduleName in $Name) {
            $parameter = Get-CiModuleInstallParameter -Name $moduleName -ModuleRoot $owner.Path
            Save-Module @parameter
        }
        & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'CiDependencyProbe.ps1') -ModuleRoot $owner.Path
        if ($LASTEXITCODE -ne 0) { throw 'Isolated dependency closure validation failed.' }
        return $owner
    } catch {
        Remove-CiDependencyRoot -Owner $owner
        throw
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $owner = Save-CiPowerShellModule -Name $Name -ModuleRoot $ModuleRoot
    if ($env:GITHUB_OUTPUT) {
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "moduleRoot=$($owner.Path)"
    }
    Write-Information "Saved dependencies to owned disposable root '$($owner.Path)'." -InformationAction Continue
}
