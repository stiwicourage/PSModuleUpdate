BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-PSModuleUpdate' -Tag 'PMU' {
    It 'supports mutually exclusive name and URI parameter sets with shared policy and credential inputs' {
        $command = Get-Command Get-PSModuleUpdate
        $command.ParameterSets.Name | Sort-Object | Should -Be @('ByModule', 'ByRepositoryUri')
        $uriSet = $command.ParameterSets | Where-Object Name -eq ByRepositoryUri
        $uriSet.Parameters.Name | Should -Contain RepositoryUri
        $uriSet.Parameters.Name | Should -Not -Contain Repository
        $command.Parameters['RepositoryUri'].ParameterType | Should -Be ([uri])
        $command.Parameters.Keys | Should -Not -Contain Authentication
    }
    It 'has exactly the public planning parameters and mandatory scalar module binding' {
        $command = Get-Command Get-PSModuleUpdate
        @($command.ParameterSets | Where-Object Name -eq ByModule).Count | Should -Be 1
        $command.Parameters['Module'].ParameterType | Should -Be ([System.Management.Automation.PSModuleInfo])
        $command.Parameters['Policy'].ParameterType | Should -Be ([hashtable])
        $command.Parameters.Keys | Should -Not -Contain 'Name'
        $command.Parameters.Keys | Should -Not -Contain 'Scope'
        $command.Parameters.Keys | Should -Not -Contain 'WhatIf'
    }
    It 'plans an unmanaged installed copy without native metadata requirements' {
        $script:repositoryFixture = Initialize-PMURepositoryFixture $TestDrive
        Initialize-PMURepositoryMock
        Initialize-PMUProviderMock
        $path = Split-Path -Parent $repositoryFixture.Module.Path
        Test-Path (Join-Path $path 'PSGetModuleInfo.xml') | Should -BeFalse
        Mock Read-NativeInstallationRecord { throw 'Planning must not require native metadata.' }
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -Policy @{ Channel = 'IncludePrerelease' }
        $plan.InstalledVersion | Should -BeExactly '2.0.0-preview.1'
        $plan.TargetVersion | Should -BeExactly '2.0.0-preview.2'
        $plan.Scope | Should -BeExactly 'CurrentUser'
        Should -Invoke Read-NativeInstallationRecord -Times 0
    }
    Context 'missing package public boundary' -Tag 'PMUPackageNotFound' {
        BeforeEach {
            $script:repositoryFixture = Initialize-PMURepositoryFixture $TestDrive
            Initialize-PMURepositoryMock
            Mock Find-PSResource { throw (Get-PMUTestProviderFailure $ProviderId) }
            Mock Register-UpdatePlan {}
            Mock Save-ProviderResource { throw 'Package acquisition must not start.' }
            Mock Install-ProviderResource { throw 'Installation must not start.' }
        }
        It 'terminates without producing or registering a plan for <ProviderId>' -ForEach @(
            @{ ProviderId = 'PackageNotFound' }
            @{ ProviderId = 'PackageNotFound,Microsoft.PowerShell.PSResourceGet.Cmdlets.FindPSResource' }
        ) {
            $plans = [Collections.Generic.List[object]]::new()
            $invoke = {
                Get-PSModuleUpdate -Module $script:repositoryFixture.Module -Repository PublicFixture |
                    ForEach-Object { $plans.Add($_) }
            }
            $invoke | Should -Throw -ErrorId 'PMU.PackageNotFound'
            $plans.Count | Should -Be 0
            Should -Invoke Register-UpdatePlan -Times 0 -Exactly
            Should -Invoke Save-ProviderResource -Times 0 -Exactly
            Should -Invoke Install-ProviderResource -Times 0 -Exactly
            Should -Invoke Find-PSResource -Times 1 -Exactly -ParameterFilter { $ErrorAction -eq 'Stop' -and $Repository[0] -eq 'PublicFixture' }
        }
    }
}
