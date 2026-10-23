function Get-PlanInstallationField {
    param([object]$Context)
    [ordered]@{
        Scope = $Context.Policy.Scope
        DestinationRoot = $Context.Installed.Root
        InstalledVersion = $Context.Installed.FullVersion
        InstalledManifestPath = $Context.Installed.ManifestPath
        ObservedInstalledVersions = @($Context.Observed)
        RepositoryName = $Context.Source.Name
        RepositoryUri = $Context.Source.Uri
        RepositoryApiVersion = $Context.Source.ApiVersion
        RepositoryTrusted = $Context.Source.Trusted
    }
}
