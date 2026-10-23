function Initialize-PlanningContext {
    param([System.Management.Automation.PSModuleInfo]$Module, [object]$Repository, [hashtable]$Policy)
    $resolved = ConvertTo-UpdatePolicy $Policy
    [pscustomobject]@{
        Module = $Module; Policy = $resolved; Provider = Get-ProviderContext
        Reference = Get-ModuleReferenceIdentity $Module
        Active = Get-ActiveModuleIdentity $Module
        Source = Get-SelectedRepository $Repository $resolved.ExpectedRepositoryUri
    }
}
