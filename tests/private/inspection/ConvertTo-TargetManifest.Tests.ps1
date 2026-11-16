BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-TargetManifest' -Tag 'PMU', 'PMUTargetManifest' {
    It 'exposes only the documented identity and data-only manifest fields' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $manifest = @{
            PrivateData = @{
                Application = @{
                    MinimumVersion = '7.0.0'
                }
            }
        }
        $result = ConvertTo-TargetManifest $operation.Plan $manifest
        $result.PSObject.Properties.Name | Sort-Object | Should -Be @('Manifest', 'ModuleGuid', 'ModuleName', 'RepositoryUri', 'Version')
        $result.Manifest.PrivateData.Application.MinimumVersion | Should -Be '7.0.0'
        $result.Version | Should -BeExactly $operation.Plan.TargetVersion
    }
}
