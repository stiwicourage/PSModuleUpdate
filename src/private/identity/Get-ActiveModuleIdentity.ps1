function Get-ActiveModuleIdentity {
    param([System.Management.Automation.PSModuleInfo]$Module)
    $loaded = @(Get-Module -Name $Module.Name | Where-Object Guid -EQ $Module.Guid | Select-Object -First 1)
    if (-not $loaded.Count) { return $null }
    $active = $loaded[0]
    [pscustomobject]@{
        Name = $active.Name; Guid = $active.Guid; Version = Get-ActiveModuleVersion $active
        ManifestPath = Assert-SafePath (Join-Path $active.ModuleBase "$($active.Name).psd1")
    }
}
