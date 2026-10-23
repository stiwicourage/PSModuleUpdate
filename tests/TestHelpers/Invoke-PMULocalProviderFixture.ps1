param([string]$Root, [string]$ModulePath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Initialize-PMUTestPackage.ps1"
. "$PSScriptRoot/Initialize-PMULocalPackage.ps1"
. "$PSScriptRoot/Get-PMUFixtureProviderRoot.ps1"
. "$PSScriptRoot/Initialize-PMULocalFixture.ps1"
. "$PSScriptRoot/Get-PMURegistrationSnapshot.ps1"
. "$PSScriptRoot/Invoke-PMULocalRelease.ps1"
. "$PSScriptRoot/Get-PMULocalSelection.ps1"
. "$PSScriptRoot/Assert-PMULicenseConsent.ps1"
. "$PSScriptRoot/Clear-PMUOwnedRegistration.ps1"
Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
Import-Module $ModulePath -Force
$fixture = Initialize-PMULocalFixture $Root
$before = Get-PMURegistrationSnapshot
$results = @()
try {
    Register-PSResourceRepository -Name $fixture.Repository -Uri $fixture.Feed
    foreach ($version in @('2.0.0-preview.2', '2.0.0-preview.3', '2.0.0', '3.0.0', '4.0.0.7')) {
        if ($version -eq '2.0.0-preview.3') { Clear-PMUOwnedRegistration $fixture $before }
        $results += Invoke-PMULocalRelease $fixture $version
    }
    $results | ConvertTo-Json -Depth 6 -Compress
} finally {
    Clear-PMUOwnedRegistration $fixture $before
}
