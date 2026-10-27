BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Complete-VerifiedInstallation' -Tag 'PMU' {
    Context 'Verified idempotent result' {
        It 'verifies an existing target without reinstalling it' {
            $operation = Initialize-PMUTestOperation $TestDrive
            Mock Assert-InstalledPackage {}
            Mock Clear-CompletedOperation {}
            Mock Install-ProviderResource {}
            $result = Complete-VerifiedInstallation $operation @() $true
            $result.Outcome | Should -Be 'AlreadyInstalled'
            Should -Invoke Assert-InstalledPackage -Times 1
            Should -Invoke Install-ProviderResource -Times 0
        }
    }
    It 'rejects a plan that does not authorize a newer target before changing anything' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $operation.Plan.UpdateAvailable = $false
        Mock Initialize-Replacement {}
        Mock Invoke-ProviderInstallation {}
        { Complete-VerifiedInstallation $operation @() $false } | Should -Throw -ErrorId 'PMU.PlanStale'
        Should -Invoke Initialize-Replacement -Times 0
        Should -Invoke Invoke-ProviderInstallation -Times 0
    }
    It 'finalizes independently verified worker output without running another provider writer' -Tag 'PMUNativeHandoff' {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:verifiedRoot = $operation.Plan.DestinationRoot
        Mock Resolve-ModuleInstallationRoot { $script:verifiedRoot }
        Invoke-PMUFixtureInstallation $operation
        Write-RecoveryJournalState $operation.Journal 'Verification'
        Mock Initialize-Replacement { throw 'The worker transaction already exists.' }
        Mock Invoke-ProviderInstallation { throw 'The parent must not install again.' }
        $tree = @($operation.Journal.StagedTree)
        $result = Complete-VerifiedInstallation $operation $tree $false
        $result.Outcome | Should -BeExactly 'Installed'
        (Read-RecoveryJournal $operation).State | Should -BeExactly 'Completed'
        Should -Invoke Invoke-ProviderInstallation -Times 0
    }
}
