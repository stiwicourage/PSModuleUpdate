# The real public workflow owns full staging/rollback coverage; this test isolates lock-held revalidation.
BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    function Invoke-NativeHandoff {
    }
}
Describe 'Invoke-LockedInstallation' -Tag 'PMU' {
    It 'rechecks environment after lock acquisition before staging or recovery changes' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-PlanEnvironment { Write-PMUError 'PMU.RepositoryChanged' 'fixture changed' }
        Mock Initialize-StagedPackage {}
        { Invoke-LockedInstallation $operation } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
        Should -Invoke Initialize-StagedPackage -Times 0
    }
    It 'delegates staging and native mutation to the lock-handoff worker rather than a parent writer' -Tag 'PMUNativeHandoff' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-PlanEnvironment {}
        Mock Repair-UnfinishedInstallation {}
        Mock Test-InstalledPlanState { $false }
        Mock Clear-CompletedOperation {}
        Mock Assert-ExactTarget {}
        Mock Assert-InstallationConsent {}
        Mock Initialize-StagedPackage { throw 'The parent must not perform provider staging.' }
        Mock Invoke-NativeHandoff { @() }
        Mock Complete-VerifiedInstallation { [pscustomobject]@{ Outcome = 'Installed' } }
        (Invoke-LockedInstallation $operation).Outcome | Should -BeExactly 'Installed'
        Should -Invoke Invoke-NativeHandoff -Times 1
        Should -Invoke Initialize-StagedPackage -Times 0
    }
}
