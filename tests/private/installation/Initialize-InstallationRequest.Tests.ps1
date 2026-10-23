BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Initialize-InstallationRequest' -Tag 'PMU' {
    It 'performs read-only prevalidation without acquiring a lock' {
        $operation = Initialize-PMUTestOperation $TestDrive
        Mock Assert-PlanEnvironment {}
        Mock Assert-ExactTarget {}
        Mock Test-InstalledPlanState { $false }
        Mock Enter-InstallationLock {}
        $request = Initialize-InstallationRequest $operation.Plan $null @{}
        $request.Plan | Should -Be $operation.Plan
        Should -Invoke Enter-InstallationLock -Times 0
    }
}
