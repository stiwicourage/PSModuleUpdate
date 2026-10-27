[CmdletBinding()]
param(
    [string[]]$Name = @('Pester', 'NovaModuleTools', 'KeepAChangelog', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet', 'Microsoft.PowerShell.PlatyPS'),
    [string]$ModuleRoot = (Join-Path ([IO.Path]::GetTempPath()) "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))")
)

. (Join-Path $PSScriptRoot 'CiDependencyRoot.ps1')

$script:PinnedVersion = @{
    Pester = '5.7.1'
    'Microsoft.PowerShell.PSResourceGet' = '1.2.0'
}
$script:DownloadAttemptLimit = 5

function Get-CiModuleInstallParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$ModuleRoot
    )

    $parameter = Get-CiModuleSaveParameter -Name $Name -ModuleRoot $ModuleRoot
    if ($script:PinnedVersion.ContainsKey($Name)) {
        $parameter['RequiredVersion'] = $script:PinnedVersion[$Name]
    }

    return $parameter
}

function Get-CiModuleSaveParameter {
    param([string]$Name, [string]$ModuleRoot)

    return @{
        Name = $Name
        Repository = 'PSGallery'
        Path = $ModuleRoot
        Force = $true
        ErrorAction = 'Stop'
    }
}

function Save-CiPowerShellModule {
    param(
        [string[]]$Name,
        [Parameter(Mandatory)][string]$ModuleRoot
    )

    $owner = New-CiDependencyRoot -Path $ModuleRoot
    try {
        Save-CiModuleSet -Name $Name -ModuleRoot $owner.Path
        return $owner
    } catch {
        Remove-CiDependencyRoot -Owner $owner
        throw
    }
}

function Save-CiModuleSet {
    param([string[]]$Name, [string]$ModuleRoot)
    $registered = Open-CiGallery
    try {
        $null = Assert-CiGallery
        foreach ($moduleName in $Name) {
            Save-CiModuleDownload (Get-CiModuleInstallParameter -Name $moduleName -ModuleRoot $ModuleRoot)
        }
        Assert-CiDependencyClosure -ModuleRoot $ModuleRoot
    } finally {
        Close-CiGallery -Registered $registered
    }
}

function Open-CiGallery {
    param()
    $repository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($repository) { return $false }
    Register-CiGallery
    return $true
}

function Register-CiGallery {
    param()
    Register-PSRepository -Default -ErrorAction Stop
}

function Assert-CiGallery {
    param()
    $repository = Get-PSRepository -Name PSGallery -ErrorAction Stop
    if ($repository.SourceLocation.TrimEnd('/') -cne 'https://www.powershellgallery.com/api/v2') {
        throw 'CI dependencies require the official PSGallery repository.'
    }
    return $repository
}

function Close-CiGallery {
    param([bool]$Registered)
    if (-not $Registered) { return }
    $repository = Assert-CiGallery
    if ($repository.InstallationPolicy -cne 'Untrusted') {
        throw 'The temporary PSGallery registration changed; refusing to remove it.'
    }
    Unregister-PSRepository -Name PSGallery -ErrorAction Stop
}

function Save-CiModuleDownload {
    param([hashtable]$Parameter)
    foreach ($attempt in 1..$script:DownloadAttemptLimit) {
        try {
            $null = Save-Module @Parameter
            return
        } catch {
            if ($attempt -eq $script:DownloadAttemptLimit) { throw }
            Write-Warning "CI download for '$($Parameter.Name)' failed (attempt $attempt/$script:DownloadAttemptLimit); retrying the same Gallery request."
            Start-Sleep -Seconds $attempt
        }
    }
}

function Assert-CiDependencyClosure {
    param([string]$ModuleRoot)
    & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'CiDependencyProbe.ps1') -ModuleRoot $ModuleRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Isolated dependency closure validation failed.'
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $owner = Save-CiPowerShellModule -Name $Name -ModuleRoot $ModuleRoot
    if ($env:GITHUB_OUTPUT) {
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "moduleRoot=$($owner.Path)"
    }
    Write-Information "Saved dependencies to owned disposable root '$($owner.Path)'." -InformationAction Continue
}
