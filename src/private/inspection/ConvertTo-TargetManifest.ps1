function ConvertTo-TargetManifest {
    param(
        [object]$Plan,
        [hashtable]$Manifest
    )
    [pscustomobject]@{
        PSTypeName = 'PSModuleUpdate.TargetManifest'
        Manifest = $Manifest
        ModuleName = $Plan.ModuleName
        ModuleGuid = $Plan.ModuleGuid
        Version = $Plan.TargetVersion
        RepositoryUri = $Plan.RepositoryUri
    }
}
