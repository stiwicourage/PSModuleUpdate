BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-InstalledPackage' -Tag 'PMU', 'PMUCoverage' {
    It 'rejects a correct manifest with a partially installed code tree' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:expectedRoot = $operation.Plan.DestinationRoot
        Mock Resolve-ModuleInstallationRoot { $script:expectedRoot }
        $null = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '2.0.0-preview.2'
        [IO.File]::WriteAllText("$($operation.Plan.TargetInstalledPath)/FixtureModule.psm1", 'partial')
        { Assert-InstalledPackage $operation @($operation.Journal.StagedTree) } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }

    It 'rejects a destination outside the planned scope root before inspecting its manifest' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:expectedRoot = Join-Path $TestDrive 'different-scope'
        Mock Resolve-ModuleInstallationRoot { $script:expectedRoot }
        Mock Get-ManifestIdentity {}
        { Assert-InstalledPackage $operation @($operation.Journal.StagedTree) } |
            Should -Throw -ErrorId 'PMU.VerificationFailed' -ExpectedMessage 'The provider destination does not match the planned scope root.'
        Should -Invoke Get-ManifestIdentity -Times 0
    }

    It 'rejects an intact installed package that is not discoverable at its exact manifest path' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:expectedRoot = $operation.Plan.DestinationRoot
        Mock Resolve-ModuleInstallationRoot { $script:expectedRoot }
        $null = Initialize-PMUTestPackage $operation.Plan.DestinationRoot '2.0.0-preview.2'
        Mock Get-Module { @() }
        { Assert-InstalledPackage $operation @($operation.Journal.StagedTree) } |
            Should -Throw -ErrorId 'PMU.VerificationFailed' -ExpectedMessage 'The installed module is not discoverable at its exact manifest path.'
        Should -Invoke Get-Module -Times 1 -Exactly -ParameterFilter {
            $ListAvailable -and $Name -ceq (Join-Path $operation.Plan.TargetInstalledPath 'FixtureModule.psd1')
        }
    }
}
