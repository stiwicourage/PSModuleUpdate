function Get-PlanRuntimeField {
    param([object]$Context)
    $active = Get-ActivePlanField $Context
    [ordered]@{
        SchemaVersion = 1
        CreatedAtUtc = [datetime]::UtcNow
        PmuVersion = '0.1.0-preview'
        ProviderName = $Context.Provider.Name
        ProviderVersion = "$($Context.Provider.Version)"
        ModuleName = $Context.Reference.Name
        ModuleGuid = $Context.Reference.Guid
        ActiveVersion = $active.Version
        ActivePath = $active.Path
        ActiveScope = $active.Scope
    }
}
