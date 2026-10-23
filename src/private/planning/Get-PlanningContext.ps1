function Get-PlanningContext {
    param([System.Management.Automation.PSModuleInfo]$Module, [object]$Repository, [hashtable]$Policy, [pscredential]$Credential)
    $context = Initialize-PlanningContext $Module $Repository $Policy
    $lease = Open-RepositoryTransport $context.Source
    $failure = $null
    try { Complete-PlanningContext $context $lease.Name $Credential }
    catch { $failure = $_; throw }
    finally { Close-RepositoryTransport $lease $failure }
}
