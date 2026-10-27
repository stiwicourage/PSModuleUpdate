BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-PlanningUpdateTarget' -Tag 'PMU', 'PMUStructuralRefinement' {
    BeforeEach {
        $script:availablePlanningResources = @('2.0.0', '3.0.0-preview2') | ForEach-Object {
            $parts = $_.Split('-')
            [pscustomobject]@{
                Name = 'FixtureModule'
                Version = [version]$parts[0]
                Prerelease = $(if ($parts.Count -gt 1) { $parts[1] } else { '' })
                AdditionalMetadata = @{ RequireLicenseAcceptance = "$($parts.Count -gt 1)" }
                Dependencies = @()
            }
        }
        $script:forwardedPlanningRequest = $null
        $script:forwardedPlanningCredential = $null
        Mock Find-ProviderResource {
            $script:forwardedPlanningRequest = $Request
            $script:forwardedPlanningCredential = $Credential
            $script:availablePlanningResources
        }
        $script:planningSelectionContext = [pscustomobject]@{
            Module = [pscustomobject]@{ Name = 'FixtureModule' }
            Policy = @{ Channel = 'Stable'; VersionRange = '[2.0.0,)' }
        }
    }
    It 'selects the <Channel> outcome while retaining transport, range, credential and license policy' -ForEach @(
        @{ Channel = 'Stable'; ExpectedVersion = '2.0.0'; Prerelease = $false; License = $false }
        @{ Channel = 'IncludePrerelease'; ExpectedVersion = '3.0.0-preview2'; Prerelease = $true; License = $true }
    ) {
        $planningSelectionContext.Policy.Channel = $Channel
        $credential = [pscredential]::new('fixture', [securestring]::new())
        $target = Get-PlanningUpdateTarget $planningSelectionContext 'OwnedTransport' $credential
        $target.Version.FullVersion | Should -BeExactly $ExpectedVersion
        $target.RequiresLicenseAcceptance | Should -Be $License
        $forwardedPlanningRequest.Name | Should -BeExactly 'FixtureModule'
        $forwardedPlanningRequest.Repository | Should -BeExactly 'OwnedTransport'
        $forwardedPlanningRequest.Version | Should -BeExactly '[2.0.0,)'
        $forwardedPlanningRequest.Prerelease | Should -Be $Prerelease
        [object]::ReferenceEquals($forwardedPlanningCredential, $credential) | Should -BeTrue
    }
    It 'reports an empty repository instead of manufacturing a successful selection' {
        $script:availablePlanningResources = @()
        { Get-PlanningUpdateTarget $planningSelectionContext 'OwnedTransport' $null } |
            Should -Throw -ErrorId 'PMU.PackageNotFound'
    }
}
