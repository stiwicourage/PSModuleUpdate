function ConvertTo-ManifestWorkerContext {
    param(
        [object]$Operation,
        [string]$ModulePath
    )
    [pscustomobject]@{
        Operation = ConvertTo-NativeWorkerOperation $Operation ([pscustomobject]@{
                Source = [pscustomobject]@{
                    Name = $Operation.RepositoryName
                }
            })
        ModulePath = $ModulePath
        InspectManifest = $true
    }
}
