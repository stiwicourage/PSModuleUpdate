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

function Get-CiPowerShellAssetName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$RuntimeIdentifier
    )

    switch ($RuntimeIdentifier) {
        'win-x64' {return "PowerShell-$Version-win-x64.zip"}
        'linux-x64' {return "powershell-$Version-linux-x64.tar.gz"}
        'osx-arm64' {return "powershell-$Version-osx-arm64.tar.gz"}
        default {throw "Unsupported runtime identifier '$RuntimeIdentifier'."}
    }
}

function Get-CiPinnedPowerShellRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PinPath,
        [Parameter(Mandatory)][string]$Channel,
        [Parameter(Mandatory)][string]$RuntimeIdentifier
    )

    $pin = (Get-Content -LiteralPath $PinPath -Raw | ConvertFrom-Json -AsHashtable).channels
    if (-not $pin.ContainsKey($Channel)) {
        throw "PowerShell channel '$Channel' is not pinned in '$PinPath'."
    }

    $version = $pin[$Channel].version
    return [pscustomobject]@{
        Version = $version
        FileName = Get-CiPowerShellAssetName -Version $version -RuntimeIdentifier $RuntimeIdentifier
        Sha256 = $pin[$Channel].sha256[$RuntimeIdentifier]
        HashSource = 'pinned in repository'
    }
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

    $tag = (Invoke-RestMethod -Uri $script:PowerShellMetadataUri).StableReleaseTag
    $version = Resolve-CiPowerShellVersionTag -Tag $tag
    $hashFile = Join-Path $WorkDirectory 'hashes.sha256'
    Invoke-WebRequest -Uri "$script:PowerShellReleaseBase/$tag/hashes.sha256" -OutFile $hashFile
    $fileName = Get-CiPowerShellAssetName -Version $version -RuntimeIdentifier $RuntimeIdentifier

    return [pscustomobject]@{
        Version = $version
        FileName = $fileName
        Sha256 = Get-CiExpectedSha256 -HashLine @(Get-Content -LiteralPath $hashFile) -FileName $fileName
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
    $release = if ($Channel -eq 'stable') {
        Get-CiStablePowerShellRelease -RuntimeIdentifier $RuntimeIdentifier -WorkDirectory $InstallRoot
    } else {
        Get-CiPinnedPowerShellRelease -PinPath $PinPath -Channel $Channel -RuntimeIdentifier $RuntimeIdentifier
    }

    $archive = Join-Path $InstallRoot $release.FileName
    Invoke-WebRequest -Uri "$script:PowerShellReleaseBase/v$( $release.Version )/$( $release.FileName )" -OutFile $archive
    Assert-CiFileHash -Path $archive -ExpectedSha256 $release.Sha256
    $directory = Join-Path $InstallRoot "powershell-$( $release.Version )"
    Expand-CiPowerShellArchive -Archive $archive -Destination $directory

    return [pscustomobject][ordered]@{
        channel = $Channel
        version = $release.Version
        runtimeIdentifier = $RuntimeIdentifier
        fileName = $release.FileName
        sha256 = $release.Sha256
        hashSource = $release.HashSource
        directory = $directory
    }
}

function Assert-CiInstalledPowerShell {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Installation
    )

    $name = if ($Installation.runtimeIdentifier -like 'win-*') {'pwsh.exe'} else {'pwsh'}
    $record = Read-CiRuntimeProbe -Executable (Join-Path $Installation.directory $name)
    $runtime = @{
        'win-x64' = @('Windows', 'X64')
        'linux-x64' = @('Linux', 'X64')
        'osx-arm64' = @('macOS', 'Arm64')
    }
    $platform = $runtime[$Installation.runtimeIdentifier]
    if (-not $platform) { throw 'Unsupported provisioning runtime.' }
    $expected = @{ OperatingSystem = $platform[0]; Architecture = $platform[1]; PowerShellVersion = $Installation.version; PowerShellChannel = $Installation.channel; Executable = $record.Executable }
    Assert-CiRuntimeRecord -Record $record -Expected $expected
    $Installation | Add-Member -NotePropertyName executable -NotePropertyValue $record.Executable -Force
    $Installation | Add-Member -NotePropertyName runtime -NotePropertyValue $record -Force
}

function Publish-CiPowerShellInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Installation,
        [string]$ProvisioningFile
    )

    if ($env:GITHUB_PATH) {
        Add-Content -LiteralPath $env:GITHUB_PATH -Value $Installation.directory
    }
    if ($env:GITHUB_OUTPUT) {
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "version=$( $Installation.version )"
        Add-Content -LiteralPath $env:GITHUB_OUTPUT -Value "executable=$( $Installation.executable )"
    }
    if ($ProvisioningFile) {
        $Installation | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ProvisioningFile
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $installation = Install-CiPowerShell -Channel $Channel -RuntimeIdentifier $RuntimeIdentifier -InstallRoot $InstallRoot -PinPath $PinPath
    Assert-CiInstalledPowerShell -Installation $installation
    Publish-CiPowerShellInstallation -Installation $installation -ProvisioningFile $ProvisioningFile
    Write-Information "Provisioned PowerShell $( $installation.version ) ($( $installation.channel ), $( $installation.hashSource )) at $( $installation.directory )." -InformationAction Continue
}
