# Cross-cutting public plans/results must report actual session state independently of the installed reference.
BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'PMU actual loaded state' -Tag 'PMUActualActive' {
    BeforeEach {
        $script:repositoryFixture = Initialize-PMURepositoryFixture $TestDrive
        Initialize-PMURepositoryMock
        Initialize-PMUProviderMock
    }
    It 'leaves all active fields null for an unloaded target including the WhatIf result' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -Policy @{ Channel = 'IncludePrerelease' }
        $result = $plan | Install-PSModuleUpdate -WhatIf
        $plan.ActiveVersion | Should -BeNullOrEmpty
        $plan.ActivePath | Should -BeNullOrEmpty
        $plan.ActiveScope | Should -BeNullOrEmpty
        $result.ActiveVersion | Should -BeNullOrEmpty
        $plan.InstalledVersion | Should -Be '2.0.0-preview.1'
        $plan.ModuleGuid | Should -Be $repositoryFixture.Guid
    }
    It 'reports a different actually loaded version and scope instead of the supplied reference' {
        $path = Initialize-PMUTestPackage "$($repositoryFixture.Root)/Other" '1.0.0' $repositoryFixture.Guid $repositoryFixture.Name
        $script:actualLoaded = Get-Module -ListAvailable "$path/$($repositoryFixture.Name).psd1"
        Mock Get-Module { $script:actualLoaded }
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -Policy @{ Channel = 'IncludePrerelease' }
        $plan.ActiveVersion | Should -Be '1.0.0'
        $plan.ActivePath | Should -Be (Join-Path $path "$($repositoryFixture.Name).psd1")
        $plan.ActiveScope | Should -Be AllUsers
        $plan.InstalledVersion | Should -Be '2.0.0-preview.1'
    }
    It 'does not authorize a downgrade of a newer actual loaded copy' {
        $path = Initialize-PMUTestPackage "$($repositoryFixture.Root)/Other" '3.0.0' $repositoryFixture.Guid $repositoryFixture.Name
        $script:actualLoaded = Get-Module -ListAvailable "$path/$($repositoryFixture.Name).psd1"
        Mock Get-Module { $script:actualLoaded }
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -Policy @{ Channel = 'IncludePrerelease' }
        $plan.ActiveVersion | Should -Be '3.0.0'
        $plan.UpdateAvailable | Should -BeFalse
    }
    It 'does not treat a newer unloaded reference in another scope as active downgrade protection' {
        $path = Initialize-PMUTestPackage "$($repositoryFixture.Root)/Other" '3.0.0' $repositoryFixture.Guid $repositoryFixture.Name
        $reference = Get-Module -ListAvailable "$path/$($repositoryFixture.Name).psd1"
        $plan = Get-PSModuleUpdate -Module $reference -Repository PublicFixture -Policy @{ Channel = 'IncludePrerelease' }
        $plan.ActiveVersion | Should -BeNullOrEmpty
        $plan.UpdateAvailable | Should -BeTrue
        $plan.InstalledVersion | Should -Be '2.0.0-preview.1'
    }
}
