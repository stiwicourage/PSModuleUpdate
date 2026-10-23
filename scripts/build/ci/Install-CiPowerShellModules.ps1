[CmdletBinding()]
param(
    [string[]]$Name = @('Pester', 'NovaModuleTools', 'PSScriptAnalyzer', 'Microsoft.PowerShell.PSResourceGet')
)

$script:PinnedVersion = @{
    Pester = '5.7.1'
    'Microsoft.PowerShell.PSResourceGet' = '1.2.0'
}

function Get-CiModuleInstallParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $parameter = @{
        Name = $Name
        Repository = 'PSGallery'
        Scope = 'CurrentUser'
        Force = $true
        ErrorAction = 'Stop'
    }
    if ($script:PinnedVersion.ContainsKey($Name)) {
        $parameter['RequiredVersion'] = $script:PinnedVersion[$Name]
    }

    return $parameter
}

if ($MyInvocation.InvocationName -ne '.') {
    foreach ($moduleName in $Name) {
        $parameter = Get-CiModuleInstallParameter -Name $moduleName
        Install-Module @parameter
        Write-Information "Installed $moduleName from PSGallery (CurrentUser)." -InformationAction Continue
    }
}
