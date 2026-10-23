function Install-PSModuleUpdate {
    <#
    .EXTERNALHELP PSModuleUpdate-Help.xml
    .SYNOPSIS
    Applies one live exact-version module update plan.
    .DESCRIPTION
    Revalidates and stages the exact package without importing it. Same-base replacement uses
    a verified backup, durable journal, exclusive OS handle lock, and best-effort rollback.
    Only provider-generated root PSGetModuleInfo.xml is excluded from SHA256 tree comparison.
    No module is hot reloaded. Interrupted operations require safe recovery and a fresh plan.
    .PARAMETER Update
    An unmodified live PSModuleUpdate.UpdatePlan from this module instance; pipeline by value.
    .PARAMETER Credential
    Per-call provider credential; never persisted.
    .PARAMETER AcceptLicense
    Explicitly accepts provider package license requirements for this operation.
    .PARAMETER TrustRepository
    Allows this operation against an untrusted repository without changing its registration.
    .EXAMPLE
    $plan | Install-PSModuleUpdate -WhatIf
    Revalidates read-only without locking, staging, installing, or repairing recovery state.
    .EXAMPLE
    $plan | Install-PSModuleUpdate -AcceptLicense -TrustRepository
    Requests native confirmation before applying the exact approved target and scope.
    .OUTPUTS
    PSModuleUpdate.UpdateResult
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByUpdatePlan')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByUpdatePlan')][ValidateNotNull()][object]$Update,
        [Parameter(ParameterSetName = 'ByUpdatePlan')][pscredential]$Credential,
        [Parameter(ParameterSetName = 'ByUpdatePlan')][switch]$AcceptLicense,
        [Parameter(ParameterSetName = 'ByUpdatePlan')][switch]$TrustRepository
    )
    process {
        $operation = Initialize-InstallationRequest $Update $Credential @{ AcceptLicense = [bool]$AcceptLicense; TrustRepository = [bool]$TrustRepository }
        $target = "$($Update.ModuleName) $($Update.TargetVersion) from $($Update.RepositoryName ?? $Update.RepositoryUri) into $($Update.Scope)"
        if ($PSCmdlet.ShouldProcess($target, 'Install exact module update')) { Invoke-UpdateInstallation $operation }
        else { ConvertTo-DeclinedUpdateResult $Update }
    }
}
