BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'PMU standalone target and exact repository binding' -Tag 'PMU', 'PMURepositoryContracts' {
    BeforeEach {
        $script:repositoryFixture = Initialize-PMURepositoryFixture $TestDrive
        Initialize-PMURepositoryMock
        Initialize-PMUProviderMock
    }
    It 'updates an unloaded dependency-free installed target by <Selector> using <RepositoryChoice>' -ForEach @(
        @{
            Selector = 'Name'
            RepositoryChoice = 'Public'
        }
        @{
            Selector = 'Uri'
            RepositoryChoice = 'Public'
        }
        @{
            Selector = 'Name'
            RepositoryChoice = 'Private'
        }
        @{
            Selector = 'Uri'
            RepositoryChoice = 'Private'
        }
    ) {
        $credential = $null
        if ($RepositoryChoice -eq 'Private') {
            $credential = [pscredential]::new('fixture-credential-user', [securestring]::new())
        }
        $bundle = Invoke-PMURepositoryRoundTrip $repositoryFixture $RepositoryChoice $Selector $credential
        $bundle.Result.Outcome | Should -Be Installed
        $bundle.Plan.ModuleName | Should -Be $repositoryFixture.Name
        @($repositoryFixture.Module.RequiredModules).Count | Should -Be 0
        @(Get-Module -Name $repositoryFixture.Name).Count | Should -Be 0
        @($repositoryFixture.Calls.Repository | Select-Object -Unique) | Should -Be @($repositoryFixture.Repositories[$RepositoryChoice].Name)
        foreach ($call in $repositoryFixture.Calls) {
            [object]::ReferenceEquals($call.Credential, $credential) | Should -BeTrue
        }
        (ConvertTo-Json $bundle -Depth 12) | Should -Not -Match 'PSCredential|SecureString|fixture-credential-user'
        Should -Invoke Register-PSResourceRepository -Times 0
        Should -Invoke Unregister-PSResourceRepository -Times 0
    }
    It 'rejects a repointed name after URI planning before any acquisition' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $repositoryFixture.Repositories.Public.Uri -Policy @{ Channel = 'IncludePrerelease' }
        $repositoryFixture.Repositories.Public.Uri = [uri]'https://repointed.invalid/v3/index.json'
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.RepositoryChanged*'
        Should -Invoke Save-ProviderResource -Times 0
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'revalidates source binding immediately before staging after exact discovery' {
        $script:bindingFindCount = 0
        Mock Find-ProviderResource {
            $script:bindingFindCount++
            if ($script:bindingFindCount -eq 3) {
                $script:repositoryFixture.Repositories.Public.Uri = [uri]'https://changed-before-save.invalid/v3/index.json'
            }
            [pscustomobject]@{
                Name = $Request.Name
                Version = [version]'2.0.0'
                Prerelease = 'preview.2'
                AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' }
                Dependencies = @()
            }
        }
        { Invoke-PMURepositoryRoundTrip $repositoryFixture Public Uri $null } | Should -Throw -ErrorId 'PMU.RepositoryChanged*'
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'revalidates source binding after staging before install credentials can reach a changed endpoint' {
        Mock Save-ProviderResource {
            $null = Initialize-PMUTestPackage $Operation.StageRoot $Operation.Plan.TargetVersion $Operation.Plan.ModuleGuid $Operation.Plan.ModuleName
            $script:repositoryFixture.Repositories.Public.Uri = [uri]'https://changed-before-install.invalid/v3/index.json'
        }
        { Invoke-PMURepositoryRoundTrip $repositoryFixture Public Uri $null } | Should -Throw -ErrorId 'PMU.RepositoryChanged*'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'rejects simultaneous name and URI selectors without calling provider discovery' {
        { Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -RepositoryUri $repositoryFixture.Repositories.Public.Uri } | Should -Throw -ErrorId 'AmbiguousParameterSet*'
        Should -Invoke Find-ProviderResource -Times 0
    }
    It 'never substitutes another name even when it now owns the original URI' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $repositoryFixture.Repositories.Public.Uri -Policy @{ Channel = 'IncludePrerelease' }
        $repositoryFixture.Repositories.Public.Name = 'ReplacementAlias'
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable*'
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'requires an independently supplied install credential without persisting the planning credential' {
        $credential = [pscredential]::new('fixture-credential-user', [securestring]::new())
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $repositoryFixture.Repositories.Private.Uri -Credential $credential -Policy @{ Channel = 'IncludePrerelease' }
        { $plan | Install-PSModuleUpdate -TrustRepository -Confirm:$false } | Should -Throw -ErrorId 'PMU.AuthenticationFailed*'
        (ConvertTo-Json $plan -Depth 12) | Should -Not -Match 'PSCredential|fixture-credential-user'
        Test-Path $repositoryFixture.Data | Should -BeFalse
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'rejects a general package lacking a PowerShell manifest before installation' {
        Mock Save-ProviderResource {
            $null = New-Item -ItemType Directory $Operation.StagedPath -Force
            [IO.File]::WriteAllText("$($Operation.StagedPath)/general-package.dll", 'Not a PowerShell module')
        }
        { Invoke-PMURepositoryRoundTrip $repositoryFixture Public Uri $null } | Should -Throw -ErrorId 'PMU.ModuleIdentityMismatch*'
        Should -Invoke Install-ProviderResource -Times 0
    }
}
