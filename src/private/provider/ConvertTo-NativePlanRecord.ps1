function ConvertTo-NativePlanRecord {
    param([object]$Record)
    $copy = [pscustomobject]@{
        InstalledTree = @($Record.InstalledTree)
    }
    if ($Record.PSObject.Properties['InspectedManifestHash']) {
        $copy | Add-Member InspectedManifestHash $Record.InspectedManifestHash
    }
    $copy
}
