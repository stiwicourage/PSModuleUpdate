function Get-PSModuleUpdateTargetManifest {
    <#
    .EXTERNALHELP PSModuleUpdate-Help.xml
    .SYNOPSIS
    Downloads and safely reads the exact target manifest of one live update plan.
    .DESCRIPTION
    Inspects only the bound repository and exact planned candidate in an owned temporary
    workspace. Does not install, import, or execute the target. Binds the manifest internally
    to the unmodified live plan; installation rejects a differing staged manifest.
    .PARAMETER Plan
    An unmodified live plan from Get-PSModuleUpdate in this same module instance.
    .PARAMETER Credential
    Optional per-call provider credential. Never retained; supply it again to installation.
    .PARAMETER TrustRepository
    Explicit operation-scoped approval of an untrusted repository.
    .PARAMETER AcceptLicense
    Explicit acceptance of declared or undisclosed package license requirements.
    .EXAMPLE
    $target = $plan | Get-PSModuleUpdateTargetManifest -TrustRepository -AcceptLicense
    Inspect $target.Manifest.PrivateData before independently approving installation.
    .OUTPUTS
    PSModuleUpdate.TargetManifest
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][ValidateNotNull()][object]$Plan,
        [pscredential]$Credential,
        [switch]$TrustRepository,
        [switch]$AcceptLicense
    )
    process {
        $operation = Initialize-ManifestInspection $Plan $Credential $AcceptLicense.IsPresent $TrustRepository.IsPresent
        Invoke-TargetManifestInspection $operation
    }
}
