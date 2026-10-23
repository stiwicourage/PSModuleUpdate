BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-UpdatePlan' -Tag 'PMU' {
    It 'constructs exactly the schema-1 field list without runtime adapters or secrets' {
        $plan = (Initialize-PMUTestOperation $TestDrive).Plan
        $fields = 'SchemaVersion CreatedAtUtc PmuVersion ProviderName ProviderVersion ModuleName ModuleGuid ActiveVersion ActivePath ActiveScope Scope DestinationRoot InstalledVersion InstalledManifestPath ObservedInstalledVersions RepositoryName RepositoryUri RepositoryApiVersion RepositoryTrusted Channel VersionRange TargetVersion TargetNumericVersion TargetPrerelease TargetIsPrerelease TargetInstalledPath UpdateAvailable Disposition Reason RestartRequired RequiresRepositoryTrust RequiresLicenseAcceptance DependencySummary'.Split(' ')
        @($plan.PSObject.Properties.Name | Sort-Object) | Should -Be @($fields | Sort-Object)
        $plan.PSObject.TypeNames[0] | Should -Be 'PSModuleUpdate.UpdatePlan'
    }
}
