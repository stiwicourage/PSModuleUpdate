function Register-UpdatePlan {
    param(
        [object]$Plan,
        [object]$Context,
        [bool]$RequiresCredential
    )

    $record = [pscustomobject]@{
        Snapshot = ConvertTo-Json $Plan -Depth 12 -Compress
        Module = $Context.Module
        ReferencePath = $Context.Reference.ManifestPath
        WasLoaded = @(Get-Module -Name $Context.Module.Name | Where-Object { [object]::ReferenceEquals($_, $Context.Module) }).Count -gt 0
        RequiresCredential = $RequiresCredential
        SourceKind = if ($Plan.RepositoryName) {
            'Registered'
        } else {
            'TemporaryUri'
        }
        InstalledTree = @($Context.InstalledTree)
    }
    (Get-LivePlanRegistry).Add($Plan, $record)
    $Plan
}
