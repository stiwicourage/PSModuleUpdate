function Initialize-PMUInspectionMock {
    Initialize-PMURepositoryMock
    Initialize-PMUProviderMock
    Mock Invoke-ManifestAcquisition {
        $null = @(Initialize-StagedPackage $Operation)
    }
    Mock Save-ProviderResource {
        $path = Initialize-PMUTestPackage $Operation.StageRoot $Operation.Plan.TargetVersion $Operation.Plan.ModuleGuid $Operation.Plan.ModuleName
        $manifest = Join-Path $path "$($Operation.Plan.ModuleName).psd1"
        $data = [IO.File]::ReadAllText($manifest).Replace("PSData = @{", "Gerber = @{ MinimumGerberVersion = '7.0.0'; Extra = @('a', 'b') }; PSData = @{")
        [IO.File]::WriteAllText($manifest, $data)
        $script:inspectionRoot = $Operation.WorkRoot
    }
}
