function Get-PlanningUpdateTarget {
    param(
        [object]$Context,
        [string]$RepositoryName,
        [pscredential]$Credential
    )
    $request = @{
        Name = $Context.Module.Name
        Repository = $RepositoryName
        Prerelease = $Context.Policy.Channel -eq 'IncludePrerelease'
        Version = $Context.Policy.VersionRange
    }
    $releases = @(Find-ProviderResource $request $Credential | ForEach-Object { ConvertTo-ProviderRelease $_ })
    Select-UpdateTarget $releases $Context.Policy.Channel
}
