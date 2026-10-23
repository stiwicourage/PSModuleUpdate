# Public planning exercises this cross-domain context builder; provider transport is independently mocked here.
BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlanningContext' -Tag 'PMU' {
    It 'passes policy range and direct credentials only into provider discovery' {
        $operation = Initialize-PMUTestOperation $TestDrive
        $script:contextIdentity = Get-ManifestIdentity $operation.Plan.InstalledManifestPath
        Mock Get-ProviderContext { @{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = [version]'1.2.0' } }
        Mock Get-ActiveModuleIdentity { $script:contextIdentity }
        Mock Get-RepositorySnapshot { @{ Name = 'OwnedFeed'; Uri = 'https://example.invalid'; Trusted = $true; ApiVersion = 'V3' } }
        Mock Get-PlanningInstallationState { @{ Observed = @(@{ ManifestPath = $script:contextIdentity.ManifestPath }); Installed = @{}; InstalledTree = @(); RecoveryJournal = $null } }
        Mock Find-ProviderResource { @() }
        $credential = [pscredential]::new('fixture', [securestring]::new())
        { Get-PlanningContext $operation.Record.Module 'OwnedFeed' @{ VersionRange = '[2.0.0,3.0.0)' } $credential } | Should -Throw -ErrorId 'PMU.PackageNotFound'
        Should -Invoke Find-ProviderResource -Times 1 -ParameterFilter { $Credential -and $Request.Version -eq '[2.0.0,3.0.0)' }
    }
}
