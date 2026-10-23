BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Complete-PlanningContext' -Tag 'PMUUriBridge' {
    Context 'Transport discovery uses only its operation name' {
        It 'forwards the lease name and not the null public repository name' {
            $fixture = Initialize-PMURepositoryFixture $TestDrive
            $context = [pscustomobject]@{ Module = $fixture.Module; Reference = [pscustomobject]@{ Guid = $fixture.Guid }; Policy = @{ Scope = 'CurrentUser'; Channel = 'Stable'; VersionRange = $null } }
            Mock Get-PlanningInstallationState { [pscustomobject]@{ Observed = @(); Installed = $null; InstalledTree = @(); RecoveryJournal = $null } }
            Mock Assert-ReferenceInstallationLayout { }
            Mock Find-ProviderResource { }
            Mock Select-UpdateTarget { $null }
            Complete-PlanningContext $context 'ephemeral-owned-name' $null | Should -Be $context
            Should -Invoke Find-ProviderResource -Times 1 -ParameterFilter { $Request.Repository -eq 'ephemeral-owned-name' }
        }
    }
}
