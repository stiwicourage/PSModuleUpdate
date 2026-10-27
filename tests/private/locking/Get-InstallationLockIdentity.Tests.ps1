BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-InstallationLockIdentity' -Tag 'PMU', 'PMULockIdentity' {
    It 'keys ownership by module, scope, and resolved root' {
        $plan = @{
            ModuleName = 'Fixture'
            Scope = 'CurrentUser'
            DestinationRoot = '/owned/one'
        }
        $first = Get-InstallationLockIdentity $plan
        $plan.Scope = 'AllUsers'
        Get-InstallationLockIdentity $plan | Should -Not -Be $first
        $plan.Scope = 'CurrentUser'
        $plan.DestinationRoot = '/owned/two'
        Get-InstallationLockIdentity $plan | Should -Not -Be $first
    }
    It 'conservatively shares a lock for differently cased Windows and macOS root aliases' -Skip:(-not ($IsWindows -or $IsMacOS)) {
        $plan = @{
            ModuleName = 'Fixture'
            Scope = 'CurrentUser'
            DestinationRoot = '/Owned/Modules'
        }
        $first = Get-InstallationLockIdentity $plan
        $plan.DestinationRoot = '/owned/modules'
        Get-InstallationLockIdentity $plan | Should -Be $first
    }
}
