BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}
Describe 'ConvertTo-ManifestWorkerContext' -Tag 'PMU', 'PMUTargetManifest' {
    It 'binds the inspection worker to the exact operation transport without transferring a mutation lock' {
        $operation = ConvertTo-ManifestInspectionOperation (Initialize-PMUTestOperation $TestDrive)
        $operation.RepositoryName = 'owned-transport'
        Mock Resolve-ModuleInstallationRoot {
            'fixture-root'
        }
        $context = ConvertTo-ManifestWorkerContext $operation 'built-module.psm1'
        $context.ModulePath | Should -BeExactly 'built-module.psm1'
        $context.Operation.RepositoryName | Should -BeExactly 'owned-transport'
        $context.InspectManifest | Should -BeTrue
        $context.Operation.PSObject.Properties.Name | Should -Not -Contain Lock
    }
}
