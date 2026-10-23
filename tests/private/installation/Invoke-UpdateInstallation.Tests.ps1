BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/tests/TestHelpers/Import-PMUTestSource.ps1"
    . "$root/tests/TestHelpers/Initialize-PMUTestPackage.ps1"
    . "$root/tests/TestHelpers/Initialize-PMUInterruptedReplacement.ps1"
}
Describe 'Invoke-UpdateInstallation' -Tag 'PMU', 'PMULicense', 'PMUPermission', 'PMURecoverySafety' {
    BeforeEach {
        $script:fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:modules = Join-Path $fixtureRoot 'Modules'
        $script:other = Join-Path $fixtureRoot 'OtherModules'
        $script:data = Join-Path $fixtureRoot 'data'
        $script:old = Initialize-PMUTestPackage $modules '2.0.0-preview.1'
        $script:target = Initialize-PMUTestPackage (Join-Path $fixtureRoot 'package') '2.0.0-preview.2'
        $script:active = Get-Module -ListAvailable "$old/FixtureModule.psd1"
        Mock Resolve-ModuleInstallationRoot { if ($Scope -eq 'CurrentUser') { $script:modules } else { $script:other } }
        Mock Resolve-PMUDataRoot { $script:data }
        Mock Get-ProviderContext { [pscustomobject]@{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = [version]'1.2.0' } }
        Mock Get-RepositorySnapshot { [pscustomobject]@{ Name = 'OwnedFeed'; Uri = 'https://example.invalid/feed'; ApiVersion = 'V3'; Trusted = $true } }
        Mock Find-ProviderResource {
            [pscustomobject]@{ Name = 'FixtureModule'; Version = [version]'2.0.0'; Prerelease = 'preview.2'; AdditionalMetadata = @{ RequireLicenseAcceptance = 'false' }; Dependencies = @() }
        }
        Mock Save-ProviderResource {
            $parent = Join-Path $Operation.StageRoot 'FixtureModule'
            $null = New-Item $parent -ItemType Directory -Force
            Copy-Item -LiteralPath $script:target -Destination $parent -Recurse
        }
        Mock Install-ProviderResource {
            Remove-Item -LiteralPath $Operation.Plan.TargetInstalledPath -Recurse -Force
            Copy-Item -LiteralPath $script:target -Destination (Split-Path -Parent $Operation.Plan.TargetInstalledPath) -Recurse
        }
        $script:plan = Get-PSModuleUpdate -Module $active -Repository OwnedFeed -Policy @{ Channel = 'IncludePrerelease' }
    }
    It 'returns the complete schema without credentials and planning writes no data' {
        $plan.SchemaVersion | Should -Be 1
        $plan.TargetVersion | Should -Be '2.0.0-preview.2'
        $plan.PSObject.Properties.Name | Should -Not -Contain 'Credential'
        Test-Path $data | Should -BeFalse
    }
    It 'WhatIf performs no lock, staging, journal or provider mutation' {
        $result = $plan | Install-PSModuleUpdate -WhatIf
        $result.Outcome | Should -Be 'WhatIf'
        Test-Path $data | Should -BeFalse
        Should -Invoke Install-ProviderResource -Times 0
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'previews a licensed exact target without accepting a license or writing state' {
        Mock Find-ProviderResource {
            [pscustomobject]@{ Name = 'FixtureModule'; Version = [version]'2.0.0'; Prerelease = 'preview.2'; AdditionalMetadata = @{ RequireLicenseAcceptance = 'true' }; Dependencies = @() }
        }
        $licensed = Get-PSModuleUpdate -Module $active -Repository OwnedFeed -Policy @{ Channel = 'IncludePrerelease' }
        ($licensed | Install-PSModuleUpdate -WhatIf).Outcome | Should -Be 'WhatIf'
        Test-Path $data | Should -BeFalse
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'translates actual controlled-directory permission denial before acquiring a lock' -Skip:($IsWindows -or [Environment]::UserName -eq 'root') {
        $parent = Join-Path $fixtureRoot 'private-read-only'
        $null = New-Item $parent -ItemType Directory
        $script:data = Join-Path $parent 'data'
        [IO.File]::SetUnixFileMode($parent, [IO.UnixFileMode]'UserRead,UserExecute')
        try {
            { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.PermissionDenied*'
            Should -Invoke Save-ProviderResource -Times 0
        }
        finally { [IO.File]::SetUnixFileMode($parent, [IO.UnixFileMode]'UserRead,UserWrite,UserExecute') }
    }
    It 'replaces only same-base identity, verifies and makes a second call a no-op' {
        $result = $plan | Install-PSModuleUpdate -Confirm:$false
        $result.Outcome | Should -Be 'Installed'
        $result.ActiveVersion | Should -BeNullOrEmpty
        $result.InstalledVersion | Should -Be '2.0.0-preview.2'
        $repeat = $plan | Install-PSModuleUpdate -Confirm:$false
        $repeat.Outcome | Should -Be 'AlreadyInstalled'
        Should -Invoke Install-ProviderResource -Times 1 -ParameterFilter { $Operation.Reinstall }
    }
    It 'rolls back a provider exception and never returns success' {
        Mock Install-ProviderResource { throw 'injected provider failure' }
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.InstallationFailed*'
        (Get-ManifestIdentity "$old/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
    }
    It 'rolls back silent provider success with the wrong installed tree' {
        Mock Install-ProviderResource {}
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.VerificationFailed*'
        (Get-ManifestIdentity "$old/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
    }
    It 'rejects a staged GUID mismatch before provider installation' {
        $null = Initialize-PMUTestPackage (Join-Path $fixtureRoot 'package') '2.0.0-preview.2' ([guid]::NewGuid())
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.GuidMismatch*'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'rejects modified plan fields' {
        $plan.Scope = 'AllUsers'
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.InvalidPlan*'
    }
    It 'rejects a changed repository' {
        Mock Get-RepositorySnapshot { [pscustomobject]@{ Name = 'OwnedFeed'; Uri = 'https://elsewhere.invalid/feed'; ApiVersion = 'V3'; Trusted = $true } }
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.RepositoryChanged*'
    }
    It 'recovers through the public API with a missing target and a surviving older active module' {
        $survivor = Initialize-PMUTestPackage $modules '1.0.0-stablefixture'
        $activeModule = Get-Module -ListAvailable "$survivor/FixtureModule.psd1"
        $null = Initialize-PMUInterruptedReplacement $plan
        $next = Get-PSModuleUpdate -Module $activeModule -Repository OwnedFeed -Policy @{ Channel = 'IncludePrerelease' }
        { $next | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.PlanStale*'
        (Get-ManifestIdentity "$old/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'recovers a <Damage> selected installation using a surviving other-scope active identity' -ForEach @(
        @{ Damage = 'missing' }
        @{ Damage = 'partial' }
    ) {
        $survivor = Initialize-PMUTestPackage $other '1.0.0-stablefixture'
        $activeModule = Get-Module -ListAvailable "$survivor/FixtureModule.psd1"
        $null = Initialize-PMUInterruptedReplacement $plan
        if ($Damage -eq 'partial') { $null = New-Item $old -ItemType Directory }
        $next = Get-PSModuleUpdate -Module $activeModule -Repository OwnedFeed -Policy @{ Channel = 'IncludePrerelease' }
        { $next | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.PlanStale*'
        (Get-ManifestIdentity "$old/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
    }
    It 'recognizes a fully verified interrupted target instead of rolling it back' {
        $null = Initialize-PMUInterruptedReplacement $plan
        Copy-Item -LiteralPath $target -Destination (Split-Path -Parent $old) -Recurse
        $result = $plan | Install-PSModuleUpdate -Confirm:$false
        $result.Outcome | Should -Be 'AlreadyInstalled'
        $result.RecoveryStatus | Should -Be 'TargetVerified'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'requires a genuinely fresh plan after restoring an interrupted replacement' {
        $null = Initialize-PMUInterruptedReplacement $plan
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.PlanStale*'
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.InvalidPlan*'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'preserves an unrelated complete prerelease occupying the interrupted numeric target' {
        $null = Initialize-PMUInterruptedReplacement $plan
        $null = Initialize-PMUTestPackage $modules '2.0.0-preview.3'
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.RecoveryFailed*'
        (Get-ManifestIdentity "$old/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.3'
        Should -Invoke Install-ProviderResource -Times 0
    }
    It 'does not treat a partial target with a correct manifest as an already healthy install' {
        $null = $plan | Install-PSModuleUpdate -Confirm:$false
        [IO.File]::WriteAllText("$old/FixtureModule.psm1", 'partial')
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.VerificationFailed*'
        Should -Invoke Install-ProviderResource -Times 1
    }
    It 'rejects a changed installed tree before staging or mutation' {
        [IO.File]::WriteAllText("$old/FixtureModule.psm1", 'external modification')
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.InstalledStateChanged*'
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'rejects stale installed content during read-only WhatIf revalidation' {
        [IO.File]::WriteAllText("$old/FixtureModule.psm1", 'changed externally')
        { $plan | Install-PSModuleUpdate -WhatIf } | Should -Throw -ErrorId 'PMU.InstalledStateChanged*'
        Test-Path $data | Should -BeFalse
    }
    It 'rejects an untrusted journal path without touching external evidence' {
        $operation = ConvertTo-InstallationOperation $plan (Test-UpdatePlan $plan) @{ AcceptLicense = $true; TrustRepository = $true } $null
        Initialize-ControlledDirectory $operation.WorkRoot
        $journal = ConvertTo-RecoveryJournal $operation @()
        $journal.BackupPath = Join-Path $fixtureRoot 'unrelated'
        $null = New-Item $journal.BackupPath -ItemType Directory
        Write-DurableJournal $journal
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.RecoveryRequired*'
        Test-Path $journal.BackupPath | Should -BeTrue
    }
    It 'handles AllUsers permission failure without falling back to CurrentUser' {
        $null = Initialize-PMUTestPackage $other '2.0.0-preview.1'
        $allUsers = Get-PSModuleUpdate -Module $active -Repository OwnedFeed -Policy @{ Scope = 'AllUsers'; Channel = 'IncludePrerelease' }
        Mock Install-ProviderResource { throw [UnauthorizedAccessException]::new('fixture denied') }
        { $allUsers | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.PermissionDenied*'
        (Get-ManifestIdentity "$old/FixtureModule.psd1").Version.FullVersion | Should -Be '2.0.0-preview.1'
        Should -Invoke Install-ProviderResource -Times 1 -ParameterFilter { $Operation.Plan.Scope -eq 'AllUsers' }
    }
}
