function Get-PMUNativeRegistryRootProbe {
    param([string]$HomeDirectory, [string]$DataDirectory)
    $null = New-Item (Join-Path $HomeDirectory '.local/share') -ItemType Directory -Force
    if ($DataDirectory) { $null = New-Item $DataDirectory -ItemType Directory -Force }
    $start = Get-PMUNativeRegistryProbeStartInfo $HomeDirectory $DataDirectory
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $result = Receive-PMUChildProcess ([Diagnostics.Process]::Start($start))
    if ($result.ExitCode -ne 0) { throw 'Read-only native registry-root probe failed.' }
    $result.Output | ConvertFrom-Json
}

# These sibling helpers are owned by this probe, not language-enforced private functions.
function Get-PMUNativeRegistryProbeStartInfo {
    param([string]$HomeDirectory, [string]$DataDirectory)
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command')) { $start.ArgumentList.Add($argument) }
    $start.Environment['PMU_PROBE_SOURCE'] = [IO.Path]::GetFullPath("$PSScriptRoot/../../src")
    $provider = Get-Module -ListAvailable Microsoft.PowerShell.PSResourceGet | Where-Object Version -EQ '1.2.0' | Select-Object -First 1
    $start.Environment['PMU_PROBE_PROVIDER'] = $provider.Path
    $start.Environment['PMU_PROBE_HELPER'] = Join-Path $PSScriptRoot 'Get-PMUNativeRegistryRootProbe.ps1'
    $start.ArgumentList.Add('. $env:PMU_PROBE_HELPER; Get-PMUNativeRegistryProbeState | ConvertTo-Json -Compress')
    $start.Environment['HOME'] = $HomeDirectory
    $null = $start.Environment.Remove('XDG_DATA_HOME')
    if ($DataDirectory) { $start.Environment['XDG_DATA_HOME'] = $DataDirectory }
    $start
}

function Get-PMUNativeRegistryProbeState {
    $ErrorActionPreference = 'Stop'
    . "$env:PMU_PROBE_SOURCE/private/shared/Assert-SafePath.ps1"
    . "$env:PMU_PROBE_SOURCE/private/locking/Resolve-RepositoryTransportRoot.ps1"
    Import-Module $env:PMU_PROBE_PROVIDER -ErrorAction Stop
    [pscustomobject]@{
        Home = $env:HOME
        LocalData = [Environment]::GetFolderPath('LocalApplicationData')
        Store = Get-PMUNativeRegistryProbeStore
        Root = Resolve-RepositoryTransportRoot
    }
}

function Get-PMUNativeRegistryProbeStore {
    # Read the pinned provider's actual store identity without calling registry APIs or creating its store.
    $assembly = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSRepositoryInfo].Assembly
    $settings = $assembly.GetType('Microsoft.PowerShell.PSResourceGet.UtilClasses.RepositorySettings', $true)
    $settings.GetField('FullRepositoryPath', [Reflection.BindingFlags]'NonPublic,Static').GetValue($null)
}
