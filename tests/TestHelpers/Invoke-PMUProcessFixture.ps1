param([string]$Root, [ValidateSet('Update', 'Crash', 'Recover', 'RecoverBackup', 'Hold', 'Attempt', 'Loaded')][string]$Mode, [ValidateSet('OwnedFeed', 'AlternateFeed')][string]$Repository = 'OwnedFeed')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:fixtureRoot = [IO.Path]::GetFullPath($Root)
$script:fixtureMode = $Mode
. "$PSScriptRoot/Import-PMUTestSource.ps1"
Set-Item Function:\Resolve-ModuleInstallationRoot {
    param($Scope)
    if ($Scope -eq 'CurrentUser') { return Join-Path $script:fixtureRoot 'Modules' }
    Join-Path $script:fixtureRoot 'OtherModules'
}
Set-Item Function:\Resolve-PMUDataRoot {
    param($Scope)
    if ($Scope -ne 'CurrentUser') { throw 'The process fixture prohibits AllUsers mutation.' }
    Join-Path $script:fixtureRoot 'data'
}
Set-Item Function:\Get-ProviderContext { [pscustomobject]@{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = [version]'1.2.0' } }
Set-Item Function:\Get-RepositorySnapshot {
    param($Name, $ExpectedUri)
    $endpoints = @{ OwnedFeed = 'https://example.invalid/feed'; AlternateFeed = 'https://example.invalid/alternate' }
    if (-not $endpoints.ContainsKey($Name)) { throw 'Unexpected fixture repository.' }
    if ($ExpectedUri -and $ExpectedUri -ne [uri]$endpoints[$Name]) { throw 'Unexpected fixture endpoint.' }
    [pscustomobject]@{ Name = $Name; Uri = $endpoints[$Name]; ApiVersion = 'V3'; Trusted = $true }
}
Set-Item Function:\Find-ProviderResource {
    param($Request, [pscredential]$Credential)
    if ($Request.Name -ne 'FixtureModule') { throw 'Unexpected fixture package.' }
    if ($Credential) { throw 'Process fixtures never accept credentials.' }
    [pscustomobject]@{ Name = 'FixtureModule'; Version = [version]'2.0.0'; Prerelease = 'preview.2'; AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' }; Dependencies = @() }
}
Set-Item Function:\Save-ProviderResource {
    param($Operation)
    $parent = Join-Path $Operation.StageRoot 'FixtureModule'
    $null = New-Item $parent -ItemType Directory -Force
    Copy-Item -LiteralPath (Join-Path $script:fixtureRoot 'package/FixtureModule/2.0.0') -Destination $parent -Recurse
}
Set-Item Function:\Install-ProviderResource {
    param($Operation)
    Remove-Item -LiteralPath $Operation.Plan.TargetInstalledPath -Recurse -Force
    if ($script:fixtureMode -eq 'Crash') { [Environment]::Exit(73) }
    if ($script:fixtureMode -eq 'Hold') {
        [IO.File]::WriteAllText((Join-Path $script:fixtureRoot 'mutation-started'), '')
        Start-Sleep -Seconds 120
    }
    Start-Sleep -Milliseconds 500
    Copy-Item -LiteralPath (Join-Path $script:fixtureRoot 'package/FixtureModule/2.0.0') -Destination (Split-Path -Parent $Operation.Plan.TargetInstalledPath) -Recurse
    [IO.File]::AppendAllText((Join-Path $script:fixtureRoot 'installs.txt'), "installed`n")
}
$module = Get-Module -ListAvailable (Join-Path $Root 'Modules/FixtureModule/1.0.0/FixtureModule.psd1')
if ($Mode -eq 'RecoverBackup') { $module = Get-PMUBackupModuleReference $Root }
if ($Mode -eq 'Loaded') {
    $module = Import-Module (Join-Path $Root 'Modules/FixtureModule/2.0.0/FixtureModule.psd1') -PassThru
}
$plan = Get-PSModuleUpdate -Module $module -Repository $Repository -Policy @{ Channel = 'IncludePrerelease' }
if ($Mode -eq 'Update') {
    [IO.File]::WriteAllText((Join-Path $Root "ready-$PID"), '')
    $deadline = [datetime]::UtcNow.AddSeconds(30)
    while (-not (Test-Path -LiteralPath (Join-Path $Root 'start'))) {
        if ([datetime]::UtcNow -gt $deadline) { throw 'Fixture start gate timed out.' }
        Start-Sleep -Milliseconds 50
    }
}
try { Invoke-PMUProcessUpdate $plan $Mode $module }
catch { ConvertTo-PMUProcessFailure $_ $Mode }
