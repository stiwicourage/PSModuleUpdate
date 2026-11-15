# Acquisition is mocked; all public plan, consent, identity, staging and cleanup collaborators are real.
BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
    function Invoke-ManifestAcquisition {
        param($Operation)
        throw "An acquisition double is required for $($Operation.Plan.ModuleName)."
    }
}
Describe 'Get-PSModuleUpdateTargetManifest' -Tag 'PMU', 'PMUTargetManifest' {
    BeforeEach {
        $script:repositoryFixture = Initialize-PMURepositoryFixture $TestDrive
        $script:inspectionRoot = $null
        Initialize-PMUInspectionMock
        $script:plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -Policy @{
            Channel = 'IncludePrerelease'
        }
    }
    It 'exposes the four-parameter API with live plan pipeline binding' {
        $command = Get-Command Get-PSModuleUpdateTargetManifest -ErrorAction Stop
        $command.Parameters['Plan'].ParameterType | Should -Be ([object])
        $binding = $command.Parameters['Plan'].Attributes | Where-Object {
            $_ -is [Management.Automation.ParameterAttribute]
        }
        $binding.ValueFromPipeline | Should -BeTrue
        $command.Parameters.Keys | Should -Not -Contain Force
        $command.Parameters.Keys | Should -Not -Contain WhatIf
    }
    It 'returns exact identity and complete safely imported PrivateData without changing the live plan or installed files' {
        $snapshot = ConvertTo-Json $plan -Depth 12 -Compress
        $before = @(Get-FileTreeInventory $repositoryFixture.Modules) | ConvertTo-Json -Depth 6
        $result = $plan | Get-PSModuleUpdateTargetManifest
        $result.Manifest | Should -BeOfType hashtable
        $result.ModuleName | Should -BeExactly $plan.ModuleName
        $result.ModuleGuid | Should -Be $plan.ModuleGuid
        $result.Version | Should -BeExactly '2.0.0-preview.2'
        $result.RepositoryUri | Should -BeExactly $plan.RepositoryUri
        $result.Manifest.GUID | Should -Be $plan.ModuleGuid
        $result.Manifest.PrivateData.PSData.Prerelease | Should -Be 'preview.2'
        $result.Manifest.PrivateData.Gerber.MinimumGerberVersion | Should -Be '7.0.0'
        $result.Manifest.PrivateData.Gerber.Extra | Should -Be @('a', 'b')
        (ConvertTo-Json $plan -Depth 12 -Compress) | Should -BeExactly $snapshot
        (@(Get-FileTreeInventory $repositoryFixture.Modules) | ConvertTo-Json -Depth 6) | Should -BeExactly $before
        Test-Path -LiteralPath $inspectionRoot | Should -BeFalse
        @(Get-Module -Name $plan.ModuleName).Count | Should -Be 0
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'rejects a <Kind> plan before acquisition' -ForEach @(
        @{
            Kind = 'manufactured'
        }
        @{
            Kind = 'deserialized'
        }
        @{
            Kind = 'tampered'
        }
        @{
            Kind = 'other module instance'
        }
    ) {
        $inputPlan = $plan
        switch ($Kind) {
            manufactured {
                $inputPlan = [pscustomobject]@{
                    PSTypeName = 'PSModuleUpdate.UpdatePlan'
                }
            }
            deserialized {
                $inputPlan = [Management.Automation.PSSerializer]::Deserialize([Management.Automation.PSSerializer]::Serialize($plan))
            }
            tampered {
                $inputPlan.TargetVersion = '9.0.0'
            }
            'other module instance' {
                $script:PmuLivePlans = [Runtime.CompilerServices.ConditionalWeakTable[object, object]]::new()
            }
        }
        {
            Get-PSModuleUpdateTargetManifest -Plan $inputPlan
        } | Should -Throw -ErrorId 'PMU.InvalidPlan'
        Should -Invoke Invoke-ManifestAcquisition -Times 0
    }
    It 'rejects a changed repository endpoint before acquisition' {
        $repositoryFixture.Repositories.Public.Uri = [uri]'https://different.invalid/v3/index.json'
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
        Should -Invoke Invoke-ManifestAcquisition -Times 0
    }
    It 'rejects a missing exact candidate without selecting latest or downloading' {
        Mock Find-ProviderResource {
            @()
        }
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId 'PMU.PackageNotFound'
        Should -Invoke Invoke-ManifestAcquisition -Times 0
        Should -Invoke Find-ProviderResource -ParameterFilter {
            $Request.Version -eq '[2.0.0-preview.2]' -and $Request.Repository -eq 'PublicFixture'
        }
    }
    It 'rejects a stale installed tree before acquisition' {
        [IO.File]::AppendAllText((Join-Path $repositoryFixture.Module.ModuleBase "$($plan.ModuleName).psm1"), "`n# changed")
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId PMU.InstalledStateChanged
        Should -Invoke Invoke-ManifestAcquisition -Times 0
    }
    It 'rejects <Kind> package identity without importing it' -ForEach @(
        @{
            Kind = 'different GUID'
            Pattern = 'a^'
            Replacement = ''
            ErrorId = 'PMU.GuidMismatch'
        }
        @{
            Kind = 'different version'
            Pattern = "ModuleVersion = '2.0.0'"
            Replacement = "ModuleVersion = '3.0.0'"
            ErrorId = 'PMU.VerificationFailed'
        }
        @{
            Kind = 'escaping RootModule'
            Pattern = "RootModule = '[^']+'"
            Replacement = "RootModule = '../outside.psm1'"
            ErrorId = 'PMU.ModuleIdentityMismatch'
        }
        @{
            Kind = 'executable manifest'
            Pattern = "ModuleVersion = '2.0.0'"
            Replacement = "ModuleVersion = (throw 'must not execute')"
            ErrorId = 'PMU.ModuleIdentityMismatch'
        }
    ) {
        Mock Save-ProviderResource {
            $guid = $Operation.Plan.ModuleGuid
            if ($Kind -eq 'different GUID') {
                $guid = [guid]::NewGuid()
            }
            $path = Initialize-PMUTestPackage $Operation.StageRoot $Operation.Plan.TargetVersion $guid $Operation.Plan.ModuleName
            $manifest = Join-Path $path "$($Operation.Plan.ModuleName).psd1"
            [IO.File]::WriteAllText($manifest, ([IO.File]::ReadAllText($manifest) -replace $Pattern, $Replacement))
        }
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId $ErrorId
        @(Get-Module -Name $plan.ModuleName).Count | Should -Be 0
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'requires independent repository trust before acquisition' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PrivateFixture -Policy @{
            Channel = 'IncludePrerelease'
        }
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId 'PMU.RepositoryTrustRequired'
        $result = Get-PSModuleUpdateTargetManifest -Plan $plan -TrustRepository
        $result.Version | Should -Be $plan.TargetVersion
        $repositoryFixture.Repositories.Private.Trusted | Should -BeFalse
    }
    It 'rechecks license prerequisites without treating inspection as acceptance' {
        Mock Find-ProviderResource {
            [pscustomobject]@{
                Name = $Request.Name
                Version = [version]'2.0.0'
                Prerelease = 'preview.2'
                AdditionalMetadata = @{
                    RequireLicenseAcceptance = 'true'
                }
                Dependencies = @()
            }
        }
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId 'PMU.LicenseAcceptanceRequired'
        (Get-PSModuleUpdateTargetManifest -Plan $plan -AcceptLicense).Version | Should -Be $plan.TargetVersion
        {
            Install-PSModuleUpdate -Update $plan -Confirm:$false
        } | Should -Throw -ErrorId 'PMU.LicenseAcceptanceRequired'
    }
    It 'requires credentials per call without retaining or returning them' {
        $credential = [pscredential]::new('private-fixture-user', [securestring]::new())
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository PublicFixture -Credential $credential -Policy @{
            Channel = 'IncludePrerelease'
        }
        {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        } | Should -Throw -ErrorId 'PMU.AuthenticationFailed'
        $result = Get-PSModuleUpdateTargetManifest -Plan $plan -Credential $credential
        (ConvertTo-Json $result -Depth 12) | Should -Not -Match 'fixture-secret|private-fixture-user|Credential'
        (ConvertTo-Json (Test-UpdatePlan $plan) -Depth 12 -WarningAction SilentlyContinue) | Should -Not -Match 'fixture-secret|private-fixture-user'
        Should -Invoke Find-ProviderResource -ParameterFilter {
            [object]::ReferenceEquals($Credential, $credential) -and $Request.Version -eq '[2.0.0-preview.2]'
        }
    }
    It 'cleans the owned workspace and redacts provider errors on acquisition failure' {
        Mock Save-ProviderResource {
            throw [InvalidOperationException]::new('provider fixture-secret private-fixture-user')
        }
        $failure = {
            Get-PSModuleUpdateTargetManifest -Plan $plan
        }
        $failure | Should -Throw -ErrorId 'PMU.InstallationFailed' -ExpectedMessage '*diagnostics were withheld*'
        @(Get-ChildItem $repositoryFixture.Data -Directory -Filter 'inspection-*').Count | Should -Be 0
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'rejects a changed same-version manifest before install mutation even when the returned DTO was edited' {
        $result = Get-PSModuleUpdateTargetManifest -Plan $plan
        $result.Manifest.PrivateData.Gerber.MinimumGerberVersion = '0.0.0'
        Mock Save-ProviderResource {
            $null = Initialize-PMUTestPackage $Operation.StageRoot $Operation.Plan.TargetVersion $Operation.Plan.ModuleGuid $Operation.Plan.ModuleName
        }
        {
            Install-PSModuleUpdate -Update $plan -Confirm:$false
        } | Should -Throw -ErrorId 'PMU.TargetManifestChanged'
        Should -Invoke Install-ProviderResource -Times 0
        (Get-ManifestIdentity $plan.InstalledManifestPath).Version.FullVersion | Should -Be '2.0.0-preview.1'
    }
    It 'installs an unchanged inspected package and keeps planning and WhatIf acquisition-free' {
        Should -Invoke Save-ProviderResource -Times 0
        $null = Install-PSModuleUpdate -Update $plan -WhatIf
        Should -Invoke Save-ProviderResource -Times 0
        $null = Get-PSModuleUpdateTargetManifest -Plan $plan
        $result = Install-PSModuleUpdate -Update $plan -Confirm:$false
        $result.InstalledVersion | Should -Be '2.0.0-preview.2'
        $result.VerificationStatus | Should -Be Verified
    }
}
