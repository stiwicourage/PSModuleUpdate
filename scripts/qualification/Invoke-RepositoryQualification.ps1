<#
.SYNOPSIS
Runs one explicitly authorized live scenario in a disposable child HOME.
.DESCRIPTION
No build is performed. ModulePath must identify a current Nova-generated module,
or Options.ApprovedBuildSha256 must pin an explicitly approved existing build.
The latter qualifies that artifact, not concurrently changing source.
Options.Scenario is Gallery, NuGet, or Private. Private also requires a caller
RepositoryUri, SeedName, SeedVersion, and TargetVersion. Credential is optional;
otherwise the child can construct a credential from inherited ADO_PAT.
ProviderStoreApproved is coordinator authorization, not repository-store isolation.
No secret is passed on the command line or persisted to a file.
.EXAMPLE
./scripts/qualification/Invoke-RepositoryQualification.ps1 -Options @{
    Scenario = 'Gallery'; ModulePath = './dist/PSModuleUpdate/PSModuleUpdate.psd1'
} -EnableLive -ProviderStoreApproved
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][hashtable]$Options,
    [switch]$EnableLive,
    [switch]$ProviderStoreApproved,
    [pscredential]$Credential
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/QualificationSafety.ps1"
. "$PSScriptRoot/QualificationProcess.ps1"
Assert-QualificationAuthorization $EnableLive $ProviderStoreApproved

function Invoke-RepositoryQualification {
    param([hashtable]$Options, [pscredential]$Credential)
    Initialize-QualificationLaunchOption $Options
    $temporaryRoot = Get-QualificationTemporaryRoot
    try {
        New-Item -Path "$temporaryRoot/home" -ItemType Directory | Out-Null
        Invoke-QualificationChild $Options $temporaryRoot $Credential
    } finally {
        if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction Stop }
    }
}

Invoke-RepositoryQualification $Options $Credential
