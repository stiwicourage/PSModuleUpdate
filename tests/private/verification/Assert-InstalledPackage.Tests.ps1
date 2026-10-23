BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-InstalledPackage' -Tag 'PMU' {
    It 'rejects a correct manifest with a partially installed code tree' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:expectedRoot = $operation.Plan.DestinationRoot
        Mock Resolve-ModuleInstallationRoot { $script:expectedRoot }
        $null = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '2.0.0-preview.2'
        [IO.File]::WriteAllText("$($operation.Plan.TargetInstalledPath)/FixtureModule.psm1", 'partial')
        { Assert-InstalledPackage $operation @($operation.Journal.StagedTree) } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
}
