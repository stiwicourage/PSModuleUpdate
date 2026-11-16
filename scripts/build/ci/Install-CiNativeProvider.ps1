. (Join-Path $PSScriptRoot 'Install-CiPowerShellModules.ps1')

function Install-CiNativeProvider {
    param($Installation)
    $owner = Get-CiNativeRuntimeOwner -Path $Installation.directory
    $manifest = Join-Path $owner.Path 'Modules/PowerShellGet/PowerShellGet.psd1'
    Assert-CiNativeTree -Root $owner.Path -Path $manifest
    $bundled = (Import-PowerShellDataFile -LiteralPath $manifest -ErrorAction Stop).ModuleVersion
    $stage = Save-CiNativeProviderStage
    try {
        return Complete-CiNativeProviderOverlay -Installation $Installation -Stage $stage -RuntimeOwner $owner -BundledVersion $bundled
    } finally {
        Remove-CiDependencyRoot -Owner $stage
    }
}

function Complete-CiNativeProviderOverlay {
    param($Installation, [hashtable]$Stage, [hashtable]$RuntimeOwner, [string]$BundledVersion)
    $manifest = Join-Path $RuntimeOwner.Path 'Modules/PowerShellGet/PowerShellGet.psd1'
    Move-CiNativeProvider -Stage $Stage -RuntimeOwner $RuntimeOwner -ManifestPath $manifest
    $probe = Read-CiNativeProviderProbe -Executable (Get-CiInstalledPowerShellExecutable -Installation $Installation) -ManifestPath $manifest
    Assert-CiNativeProbe -Probe $probe -ManifestPath $manifest
    return Get-CiNativeProviderRecord -Probe $probe -BundledVersion $BundledVersion
}

function Get-CiNativeRuntimeOwner {
    param([string]$Path)
    $owner = Get-CiDependencyOwner -Path $Path
    if ($owner.Path -eq $PSHOME) {
        throw 'The ambient PSHOME cannot receive a native provider overlay.'
    }
    return $owner
}

function Save-CiNativeProviderStage {
    param()
    $path = Join-Path ([IO.Path]::GetTempPath()) "pmu-ci-modules-$([guid]::NewGuid().ToString('N'))"
    return Save-CiPowerShellModule -Name PowerShellGet -ModuleRoot $path -Validation {
        param($Root)
        Assert-CiNativeTree -Root $Root -Path (Join-Path $Root 'PowerShellGet/2.2.5')
        Assert-CiNativePayload -Path (Join-Path $Root 'PowerShellGet/2.2.5')
    }
}

function Assert-CiNativeTree {
    param([string]$Root, [string]$Path)
    $rootPath = [IO.Path]::GetFullPath($Root)
    $current = [IO.Path]::GetFullPath($Path)
    if (-not $current.StartsWith($rootPath + [IO.Path]::DirectorySeparatorChar)) {
        throw 'Native provider path is outside the owned runtime.'
    }
    Assert-CiNativeAncestry -Path $current -Root $rootPath
}

function Assert-CiNativeAncestry {
    param([string]$Path, [string]$Root)
    while ($Path) {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType) {
            throw "Native provider path contains a filesystem link: '$Path'."
        }
        if ($Path -eq $Root) { return }
        $Path = Split-Path -Parent $Path
    }
}

function Move-CiNativeProvider {
    param([hashtable]$Stage, [hashtable]$RuntimeOwner, [string]$ManifestPath)
    $null = Get-CiDependencyOwner -Path $Stage.Path
    $source = Join-Path $Stage.Path 'PowerShellGet/2.2.5'
    Assert-CiNativeTree -Root $Stage.Path -Path $source
    Assert-CiNativePayload -Path $source
    $actual = Get-CiDependencyOwner -Path $RuntimeOwner.Path
    if ($actual.Token -cne $RuntimeOwner.Token) { throw 'Runtime ownership changed.' }
    Assert-CiNativeTree -Root $RuntimeOwner.Path -Path $ManifestPath
    $destination = Split-Path -Parent $ManifestPath
    Remove-Item -LiteralPath $destination -Recurse -Force -ErrorAction Stop
    Move-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
}

function Assert-CiNativePayload {
    param([string]$Path)
    $manifest = Join-Path $Path 'PowerShellGet.psd1'
    $items = @(Get-Item -LiteralPath $manifest -Force -ErrorAction Stop)
    $items += @(Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop)
    if (@($items | Where-Object LinkType).Count) {
        throw 'Staged native provider contains a filesystem link.'
    }
    if ((Import-PowerShellDataFile -LiteralPath $manifest -ErrorAction Stop).ModuleVersion -cne '2.2.5') {
        throw 'Staged native provider must be PowerShellGet 2.2.5.'
    }
}

function Get-CiNativeProviderProbeCommand {
    param([string]$ManifestPath)
    return @"
`$ErrorActionPreference = 'Stop'
`$env:PSModulePath = Join-Path `$PSHOME 'Modules'
Import-Module '__MANIFEST__' -RequiredVersion 2.2.5 -ErrorAction Stop
`$module = Get-Module PowerShellGet -ErrorAction Stop
@{
    name = `$module.Name
    actualVersion = `$module.Version.ToString()
    manifestPath = Join-Path `$module.ModuleBase 'PowerShellGet.psd1'
    runtimeDirectory = `$PSHOME
} | ConvertTo-Json -Compress
"@.Replace('__MANIFEST__', $ManifestPath.Replace("'", "''"))
}

function Read-CiNativeProviderProbe {
    param([string]$Executable, [string]$ManifestPath)
    $command = Get-CiNativeProviderProbeCommand -ManifestPath $ManifestPath
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $output = & $Executable -NoLogo -NoProfile -NonInteractive -EncodedCommand $encoded
    if ($LASTEXITCODE -ne 0) {
        throw 'Selected runtime native provider import probe failed.'
    }
    return ($output -join "`n" | ConvertFrom-Json -AsHashtable -ErrorAction Stop)
}

function Assert-CiNativeProbe {
    param($Probe, [string]$ManifestPath)
    $runtime = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ManifestPath))
    foreach ($field in @{ name = 'PowerShellGet'; actualVersion = '2.2.5'; manifestPath = $ManifestPath; runtimeDirectory = $runtime }.GetEnumerator()) {
        if ($Probe[$field.Key] -cne $field.Value) {
            throw "Selected runtime native provider probe differs at '$($field.Key)'."
        }
    }
}

function Get-CiNativeProviderRecord {
    param([hashtable]$Probe, [string]$BundledVersion)
    $Probe.sourceRepository = 'PSGallery'
    $Probe.sourceUri = 'https://www.powershellgallery.com/api/v2'
    $Probe.requestedVersion = '2.2.5'
    $Probe.archiveBundledVersion = $BundledVersion
    return $Probe
}
