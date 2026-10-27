function Get-ActivePlanField {
    param([object]$Context)
    if (-not $Context.Active) {
        return @{
            Version = $null
            Path = $null
            Scope = $null
        }
    }
    $scope = $Context.Observed | Where-Object ManifestPath -CEQ $Context.Active.ManifestPath | Select-Object -First 1 -ExpandProperty Scope
    @{
        Version = $Context.Active.Version.FullVersion
        Path = $Context.Active.ManifestPath
        Scope = $scope
    }
}
