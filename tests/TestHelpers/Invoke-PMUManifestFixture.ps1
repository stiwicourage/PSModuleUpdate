param(
    [string]$Root,
    [string]$ModulePath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
foreach ($helper in @(
        'Initialize-PMUTestPackage', 'Initialize-PMULocalPackage', 'Assert-PMUNativeFixtureStore',
        'Initialize-PMUNativeLocalInstallation', 'Get-PMUFixtureProviderRoot', 'Initialize-PMULocalFixture',
        'Get-PMURegistrationSnapshot', 'Clear-PMUOwnedRegistration', 'Assert-PMUManifestInspection',
        'Initialize-PMUManifestFixture', 'Assert-PMUManifestRepublish'
    )) {
    . (Join-Path $PSScriptRoot "$helper.ps1")
}
Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
Import-Module $ModulePath -Force
function Invoke-PMUManifestFixture {
    param([string]$Root)
    $fixture = Initialize-PMULocalFixture $Root
    $before = Get-PMURegistrationSnapshot
    try {
        $plan = Get-PMUManifestFixturePlan $fixture
        Assert-PMUManifestInspection $plan $fixture
    } finally {
        Clear-PMUOwnedRegistration $fixture $before
    }
}
function Get-PMUManifestFixturePlan {
    param([object]$Fixture)
    Initialize-PMULocalPackage $Fixture '2.0.0-preview2'
    Initialize-PMUManifestFixture $Fixture '7.0.0'
    $selection = @{
        RepositoryUri = [uri]::new([IO.Path]::GetFullPath($Fixture.Feed), [UriKind]::Absolute)
    }
    Get-PSModuleUpdate -Module $Fixture.Module @selection -Policy @{
        Channel = 'IncludePrerelease'
    }
}
Invoke-PMUManifestFixture $Root
