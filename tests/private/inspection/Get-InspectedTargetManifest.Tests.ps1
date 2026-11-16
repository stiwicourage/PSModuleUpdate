BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'Get-InspectedTargetManifest' -Tag 'PMU', 'PMUTargetManifest' {
    It 'keeps the original private binding when reinspection content differs' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-PlanEnvironment {
        }
        Mock Test-InstalledPlanState {
        }
        $path = Initialize-PMUTestPackage $operation.StageRoot $operation.Plan.TargetVersion $operation.Plan.ModuleGuid
        $first = Get-InspectedTargetManifest $operation
        $hash = $operation.Record.InspectedManifestHash
        $manifest = Join-Path $path 'FixtureModule.psd1'
        [IO.File]::AppendAllText($manifest, "`n")
        {
            Get-InspectedTargetManifest $operation
        } | Should -Throw -ErrorId PMU.TargetManifestChanged
        $operation.Record.InspectedManifestHash | Should -BeExactly $hash
        $first.Version | Should -BeExactly $operation.Plan.TargetVersion
    }
}
