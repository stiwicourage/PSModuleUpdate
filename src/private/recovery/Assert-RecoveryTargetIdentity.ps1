function Assert-RecoveryTargetIdentity {
    param([object]$Journal)
    $manifest = Join-Path $Journal.TargetPath "$($Journal.ModuleName).psd1"
    $data = Get-SurvivingManifestData $manifest
    $expected = @{
        GUID = $Journal.ModuleGuid
        ModuleVersion = $Journal.TargetNumericVersion
    }
    $errorId = @{
        GUID = 'PMU.GuidMismatch'
        ModuleVersion = 'PMU.ModuleIdentityMismatch'
    }
    foreach ($key in $expected.Keys) {
        Assert-SurvivingManifestProperty $data[$key] $expected[$key] $errorId[$key]
    }
    Assert-RecoveryTargetVersion $data $Journal
}
