[CmdletBinding()]
param(
    [string]$Channel,
    [string]$RuntimeIdentifier,
    [string]$InstallRoot = (Join-Path ([System.IO.Path]::GetTempPath()) 'pmu-powershell'),
    [string]$ProvisioningFile,
    [string]$PinPath = (Join-Path $PSScriptRoot 'PowerShellVersions.json')
)

$script:PowerShellReleaseBase = 'https://github.com/PowerShell/PowerShell/releases/download'
$script:PowerShellMetadataUri = 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json'
. (Join-Path $PSScriptRoot 'CiRuntimeEvidence.ps1')
. (Join-Path $PSScriptRoot 'Install-CiNativeProvider.ps1')

function Get-CiPowerShellAssetName {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$RuntimeIdentifier
    )

    if ($RuntimeIdentifier -eq 'win-x64') {
        return "PowerShell-$Version-win-x64.zip"
    }
    return Get-CiUnixPowerShellAssetName -Version $Version -RuntimeIdentifier $RuntimeIdentifier
}

function Get-CiUnixPowerShellAssetName {
    param([string]$Version, [string]$RuntimeIdentifier)
    switch ($RuntimeIdentifier) {
        'linux-x64' {
            return "powershell-$Version-linux-x64.tar.gz"
        }
        'osx-arm64' {
            return "powershell-$Version-osx-arm64.tar.gz"
        }
        default {
            throw "Unsupported runtime identifier '$RuntimeIdentifier'."
        }
    }
}

function Get-CiPinnedPowerShellRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PinPath,
        [Parameter(Mandatory)][string]$Channel,
        [Parameter(Mandatory)][string]$RuntimeIdentifier
    )

    $pin = Get-CiPowerShellPin -PinPath $PinPath -Channel $Channel
    return [pscustomobject]@{
        Version = $pin.version
        FileName = Get-CiPowerShellAssetName -Version $pin.version -RuntimeIdentifier $RuntimeIdentifier
        Sha256 = $pin.sha256[$RuntimeIdentifier]
        HashSource = 'pinned in repository'
    }
}

function Get-CiPowerShellPin {
    param([string]$PinPath, [string]$Channel)
    $pin = (Get-Content -LiteralPath $PinPath -Raw | ConvertFrom-Json -AsHashtable).channels
    if (-not $pin.ContainsKey($Channel)) {
        throw "PowerShell channel '$Channel' is not pinned in '$PinPath'."
    }

    return $pin[$Channel]
}

function Get-CiExpectedSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$HashLine,
        [Parameter(Mandatory)][string]$FileName
    )

    foreach ($line in $HashLine) {
        if ($line -match '^\s*([0-9a-fA-F]{64})\s+\*?(\S+)\s*$' -and $Matches[2] -eq $FileName) {
            return $Matches[1].ToLowerInvariant()
        }
    }

    throw "No checksum entry found for '$FileName'."
}

function Assert-CiFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedSha256
    )

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $ExpectedSha256.ToLowerInvariant()) {
        throw "SHA-256 checksum mismatch for '$Path': expected $ExpectedSha256 but found $actual."
    }
}

function Resolve-CiPowerShellVersionTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Tag
    )

    if ($Tag -notmatch '^v(\d+\.\d+\.\d+)$') {
        throw "Release tag '$Tag' is not a stable release tag."
    }

    return $Matches[1]
}

function Get-CiStablePowerShellRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RuntimeIdentifier,
        [Parameter(Mandatory)][string]$WorkDirectory
    )

    $release = Get-CiStableReleaseInfo -RuntimeIdentifier $RuntimeIdentifier -WorkDirectory $WorkDirectory
    return [pscustomobject]@{
        Version = $release.Version
        FileName = $release.FileName
        Sha256 = Get-CiExpectedSha256 -HashLine $release.HashLine -FileName $release.FileName
        HashSource = $release.HashSource
    }
}

function Get-CiStableReleaseInfo {
    param([string]$RuntimeIdentifier, [string]$WorkDirectory)
    $tag = (Invoke-RestMethod -Uri $script:PowerShellMetadataUri).StableReleaseTag
    $version = Resolve-CiPowerShellVersionTag -Tag $tag
    $hashFile = Join-Path $WorkDirectory 'hashes.sha256'
    Invoke-WebRequest -Uri "$script:PowerShellReleaseBase/$tag/hashes.sha256" -OutFile $hashFile
    $fileName = Get-CiPowerShellAssetName -Version $version -RuntimeIdentifier $RuntimeIdentifier

    return @{
        Version = $version
        FileName = $fileName
        HashLine = @(Get-Content -LiteralPath $hashFile)
        HashSource = "hashes.sha256 of release $tag"
    }
}

function Expand-CiPowerShellArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Archive,
        [Parameter(Mandatory)][string]$Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    if ($Archive.EndsWith('.zip')) {
        Expand-Archive -LiteralPath $Archive -DestinationPath $Destination -Force
        return
    }

    Invoke-CiTarExtraction -Archive $Archive -Destination $Destination
}

function Invoke-CiTarExtraction {
    param([string]$Archive, [string]$Destination)
    & tar -xzf $Archive -C $Destination
    if ($LASTEXITCODE -ne 0) {
        throw "Extracting '$Archive' failed with exit code $LASTEXITCODE."
    }
    & chmod +x (Join-Path $Destination 'pwsh')
}

function Install-CiPowerShell {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Channel,
        [Parameter(Mandatory)][string]$RuntimeIdentifier,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$PinPath
    )

    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    $release = Resolve-CiPowerShellRelease -Channel $Channel -RuntimeIdentifier $RuntimeIdentifier -InstallRoot $InstallRoot -PinPath $PinPath
    $directory = Save-CiPowerShellArchive -Release $release -InstallRoot $InstallRoot
    $installation = Get-CiPowerShellInstallationRecord -Channel $Channel -RuntimeIdentifier $RuntimeIdentifier -Release $release -Directory $directory
    return Complete-CiPowerShellInstallation -Installation $installation
}

function Complete-CiPowerShellInstallation {
    param($Installation)
    $owner = Get-CiDependencyOwner -Path $Installation.directory
    try {
        $Installation | Add-Member -NotePropertyName nativeProvider -NotePropertyValue (Install-CiNativeProvider -Installation $Installation)
        Assert-CiInstalledPowerShell -Installation $Installation
        return $Installation
    } catch {
        Remove-CiDependencyRoot -Owner $owner
        throw
    }
}

function Resolve-CiPowerShellRelease {
    param([string]$Channel, [string]$RuntimeIdentifier, [string]$InstallRoot, [string]$PinPath)
    if ($Channel -eq 'stable') {
        Get-CiStablePowerShellRelease -RuntimeIdentifier $RuntimeIdentifier -WorkDirectory $InstallRoot
    } else {
        Get-CiPinnedPowerShellRelease -PinPath $PinPath -Channel $Channel -RuntimeIdentifier $RuntimeIdentifier
    }

}

function Save-CiPowerShellArchive {
    param($Release, [string]$InstallRoot)
    $archive = Join-Path $InstallRoot $Release.FileName
    Invoke-WebRequest -Uri "$script:PowerShellReleaseBase/v$( $Release.Version )/$( $Release.FileName )" -OutFile $archive
    Assert-CiFileHash -Path $archive -ExpectedSha256 $Release.Sha256
    $root = Resolve-CiInstallRootPath -Path $InstallRoot
    $owner = New-CiDependencyRoot -Path (Join-Path $root "pmu-ci-modules-runtime-$([guid]::NewGuid().ToString('N'))")
    try {
        Expand-CiPowerShellArchive -Archive $archive -Destination $owner.Path
        return $owner.Path
    } catch {
        Remove-CiDependencyRoot -Owner $owner
        throw
    }
}

function Resolve-CiInstallRootPath {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $resolved = $item.FullName
    while ($item) {
        if ($item.LinkType) {
            $resolved = $item.ResolveLinkTarget($true).FullName + $resolved.Substring($item.FullName.Length)
        }
        $item = $item.Parent
    }
    return $resolved
}

function Get-CiPowerShellInstallationRecord {
    param([string]$Channel, [string]$RuntimeIdentifier, $Release, [string]$Directory)
    return [pscustomobject][ordered]@{
        channel = $Channel
        version = $Release.Version
        runtimeIdentifier = $RuntimeIdentifier
        fileName = $Release.FileName
        sha256 = $Release.Sha256
        hashSource = $Release.HashSource
        directory = $Directory
    }
}

function Assert-CiInstalledPowerShell {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Installation
    )

    $record = Read-CiRuntimeProbe -Executable (Get-CiInstalledPowerShellExecutable -Installation $Installation)
    $expected = Get-CiInstalledPowerShellExpectation -Installation $Installation -Record $record
    Assert-CiRuntimeRecord -Record $record -Expected $expected
    $Installation | Add-Member -NotePropertyName executable -NotePropertyValue $record.Executable -Force
    $Installation | Add-Member -NotePropertyName runtime -NotePropertyValue $record -Force
}

function Get-CiInstalledPowerShellExecutable {
    param($Installation)
    $name = if ($Installation.runtimeIdentifier -like 'win-*') {
        'pwsh.exe'
    } else {
        'pwsh'
    }
    return Join-Path $Installation.directory $name
}

function Get-CiProvisioningPlatform {
    param([string]$RuntimeIdentifier)
    $runtime = @{
        'win-x64' = @('Windows', 'X64')
        'linux-x64' = @('Linux', 'X64')
        'osx-arm64' = @('macOS', 'Arm64')
    }
    $platform = $runtime[$RuntimeIdentifier]
    if (-not $platform) {
        throw 'Unsupported provisioning runtime.'
    }
    return $platform
}

function Get-CiInstalledPowerShellExpectation {
    param($Installation, $Record)
    $platform = Get-CiProvisioningPlatform -RuntimeIdentifier $Installation.runtimeIdentifier
    return @{
        OperatingSystem = $platform[0]
        Architecture = $platform[1]
        PowerShellVersion = $Installation.version
        PowerShellChannel = $Installation.channel
        Executable = $Record.Executable
    }
}

function Publish-CiPowerShellInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Installation,
        [string]$ProvisioningFile
    )

    Publish-CiPowerShellEnvironment -Installation $Installation
    if ($ProvisioningFile) {
        $Installation | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ProvisioningFile
    }
}

function Publish-CiPowerShellEnvironment {
    param($Installation)
    if ($env:GITHUB_PATH) {
        Add-Content -LiteralPath $env:GITHUB_PATH -Value $Installation.directory
    }
    if ($env:GITHUB_OUTPUT) {
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "version=$( $Installation.version )"
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "executable=$( $Installation.executable )"
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $installation = Install-CiPowerShell -Channel $Channel -RuntimeIdentifier $RuntimeIdentifier -InstallRoot $InstallRoot -PinPath $PinPath
    Publish-CiPowerShellInstallation -Installation $installation -ProvisioningFile $ProvisioningFile
    Write-Information "Provisioned PowerShell $( $installation.version ) ($( $installation.channel ), $( $installation.hashSource )) at $( $installation.directory )." -InformationAction Continue
}
