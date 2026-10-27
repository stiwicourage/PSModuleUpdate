function Get-PSModuleUpdate {
    <#
    .EXTERNALHELP PSModuleUpdate-Help.xml
    .SYNOPSIS
    Creates an exact-version update plan without changing installed PowerShell modules.
    .DESCRIPTION
    Inspects a compatible installed module in CurrentUser or AllUsers and one exact repository.
    The target need not be loaded, be the caller, or depend on PSModuleUpdate.
    Policy defaults to Stable and CurrentUser. Credentials are used only in memory.
    An unregistered URI uses an ephemeral untrusted registration and nonsecret ownership receipt.
    Cleanup validates exact registration identity. An interrupted unbound receipt fails closed.
    .PARAMETER Module
    One installed module reference. Name and GUID must match its on-disk manifest.
    .PARAMETER Repository
    One literal registered PSResourceGet repository name.
    .PARAMETER RepositoryUri
    Exact endpoint. Reuses one matching registration or creates an owned temporary transport.
    .PARAMETER Policy
    Channel, Scope, ExpectedRepositoryUri (Uri), and VersionRange. Unknown keys are rejected.
    .PARAMETER Credential
    Optional per-call provider credential. Supply it again when installing.
    .EXAMPLE
    Get-PSModuleUpdate -Module (Get-Module ExampleModule) -Repository PSGallery
    Creates a stable CurrentUser update plan without changing installed files.
    .EXAMPLE
    Get-PSModuleUpdate -Module $installed -RepositoryUri ([uri]'https://api.nuget.org/v3/index.json')
    Uses only the specified endpoint. Packages must contain a valid PowerShell module manifest.
    .OUTPUTS
    PSModuleUpdate.UpdatePlan
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByModule')]
    param(
        [Parameter(Mandatory)][System.Management.Automation.PSModuleInfo]$Module,
        [Parameter(Mandatory, ParameterSetName = 'ByModule')][ValidateNotNullOrEmpty()][string]$Repository,
        [Parameter(Mandatory, ParameterSetName = 'ByRepositoryUri')][ValidateNotNull()][uri]$RepositoryUri,
        [hashtable]$Policy = @{},
        [pscredential]$Credential
    )
    $selection = @{
        Name = $Repository
        Uri = $RepositoryUri
    }
    $context = Get-PlanningContext $Module $selection $Policy $Credential
    Register-UpdatePlan (ConvertTo-UpdatePlan $context) $context ([bool]$Credential)
}
