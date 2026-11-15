BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-NativeSnapshotPath' -Tag 'PMU' {
    It 'selects only the original or already installed planned target' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.TargetInstalledPath = Join-Path $TestDrive 'target'
        Get-NativeSnapshotPath $operation $false | Should -BeExactly (Split-Path -Parent $operation.Plan.InstalledManifestPath)
        Get-NativeSnapshotPath $operation $true | Should -BeExactly $operation.Plan.TargetInstalledPath
    }
}
