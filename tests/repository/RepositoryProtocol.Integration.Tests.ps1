# Opt-in cross-component qualification; never run live feeds in ordinary suites.
BeforeAll {
    $script:qualificationRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:modulePath = "$qualificationRoot/dist/PSModuleUpdate/PSModuleUpdate.psd1"
    $script:launcher = "$qualificationRoot/scripts/qualification/Invoke-RepositoryQualification.ps1"
    function Test-QualificationPrivateInput {
        foreach ($name in @('ADO_PAT', 'PMU_QUALIFICATION_PRIVATE_URI', 'PMU_QUALIFICATION_PRIVATE_MODULE', 'PMU_QUALIFICATION_PRIVATE_SEED', 'PMU_QUALIFICATION_PRIVATE_TARGET')) {
            if (-not [Environment]::GetEnvironmentVariable($name)) {
                return $false
            }
        }
        $true
    }
    function Assert-QualificationLiveUnloadedState {
        param([object]$Evidence)
        ($null -eq $Evidence.Plan.ActiveVersion) | Should -BeTrue
        ($null -eq $Evidence.Plan.ActivePath) | Should -BeTrue
        ($null -eq $Evidence.Plan.ActiveScope) | Should -BeTrue
        ($null -eq $Evidence.Result.ActiveVersion) | Should -BeTrue
    }
}

Describe 'Live repository protocol qualification' -Tag 'RepositoryLive' -Skip:($env:PMU_QUALIFICATION_LIVE -ne '1') {
    It 'updates an unloaded independent ThreadJob module from PSGallery with exact source binding' {
        $options = @{
            Scenario = 'Gallery'
            ModulePath = $modulePath
        }
        $result = & $launcher -Options $options -EnableLive -ProviderStoreApproved:($env:PMU_QUALIFICATION_STORE_APPROVED -eq '1')
        $result.Outcome | Should -Be 'Passed'
        $result.Cleanup | Should -Be 'Passed'
        $result.Plan.TargetVersion | Should -Be '2.1.0'
        $result.Result.InstalledVersion | Should -Be '2.1.0'
        $result.Result.VerificationStatus | Should -Be 'Verified'
        $result.Result.RepositoryUri | Should -Be 'https://www.powershellgallery.com/api/v2'
        $result.SourcePolicyMismatchRejected | Should -BeTrue
        $result.WhatIfInstallationUnchanged | Should -BeTrue
        $result.SeedWasLoaded | Should -BeFalse
        Assert-QualificationLiveUnloadedState $result
    }

    It 'rejects a real NuGet.org nonmodule package before any installation mutation' {
        $options = @{
            Scenario = 'NuGet'
            ModulePath = $modulePath
        }
        $result = & $launcher -Options $options -EnableLive -ProviderStoreApproved:($env:PMU_QUALIFICATION_STORE_APPROVED -eq '1')
        $result.Cleanup | Should -Be 'Passed'
        if ($result.Outcome -eq 'ProviderLimitation') {
            Set-ItResult -Inconclusive -Because 'PSResourceGet rejected the nonmodule before PMU package validation; PMU rejection NOT TESTED.'
            return
        }
        $result.Outcome | Should -Be 'NonModuleRejected'
        $result.InstallationUnchanged | Should -BeTrue
    }

    It 'updates a caller-selected private module with separate credentials and credential-free results' {
        if (-not (Test-QualificationPrivateInput)) {
            Set-ItResult -Skipped -Because 'NOT TESTED: caller-approved endpoint, credential, or pinned private module fixture absent.'
            return
        }
        $options = @{
            Scenario = 'Private'
            ModulePath = $modulePath
            RepositoryUri = $env:PMU_QUALIFICATION_PRIVATE_URI
            SeedName = $env:PMU_QUALIFICATION_PRIVATE_MODULE
            SeedVersion = $env:PMU_QUALIFICATION_PRIVATE_SEED
            TargetVersion = $env:PMU_QUALIFICATION_PRIVATE_TARGET
        }
        $result = & $launcher -Options $options -EnableLive -ProviderStoreApproved:($env:PMU_QUALIFICATION_STORE_APPROVED -eq '1')
        $result.Outcome | Should -Be 'Passed'
        $result.Cleanup | Should -Be 'Passed'
        $result.CredentialFree | Should -BeTrue
        $result.SourcePolicyMismatchRejected | Should -BeTrue
        $result.Result.TargetVersion | Should -Be $options.TargetVersion
        Assert-QualificationLiveUnloadedState $result
    }
}
