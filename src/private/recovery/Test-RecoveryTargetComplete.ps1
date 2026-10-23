function Test-RecoveryTargetComplete {
    param([object]$Journal)
    try {
        $identity = Get-ManifestIdentity (Join-Path $Journal.TargetPath "$($Journal.ModuleName).psd1")
        if ($identity.Guid -ne [guid]$Journal.ModuleGuid -or $identity.Version.FullVersion -cne $Journal.TargetVersion) { return $false }
        Assert-FileTreeEqual @($Journal.StagedTree) @(Get-FileTreeInventory $Journal.TargetPath)
        return $true
    }
    catch { return $false }
}
