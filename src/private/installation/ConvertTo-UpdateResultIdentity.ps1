function ConvertTo-UpdateResultIdentity {
    param([object]$Plan)

    [ordered]@{
        ModuleName = $Plan.ModuleName
        ModuleGuid = $Plan.ModuleGuid
        RepositoryName = $Plan.RepositoryName
        RepositoryUri = $Plan.RepositoryUri
        Scope = $Plan.Scope
        ActiveVersion = $Plan.ActiveVersion
    }
}
