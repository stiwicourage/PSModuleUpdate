function Assert-RecoveryTargetIdentity {
    param([object]$Journal)
    $manifest = Join-Path $Journal.TargetPath "$($Journal.ModuleName).psd1"
    $data = Get-SurvivingManifestData $manifest
    $expected = @{ GUID = $Journal.ModuleGuid; ModuleVersion = $Journal.TargetNumericVersion }
    $errorId = @{ GUID = 'PMU.GuidMismatch'; ModuleVersion = 'PMU.ModuleIdentityMismatch' }
    foreach ($key in $expected.Keys) {
        if (-not $data[$key]) { continue }
        if ("$($data[$key])" -ine $expected[$key]) {
            Write-PMUError $errorId[$key] 'Recovery refuses to delete an installation with an unexpected manifest identity.'
        }
    }
    Assert-RecoveryTargetVersion $data $Journal
}
