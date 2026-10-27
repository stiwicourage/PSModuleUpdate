BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Assert-NativeCandidate' -Tag 'PMU', 'PMUNativeCandidate' {
    BeforeEach {
        $manifest = Join-Path $TestDrive 'FixtureModule.psd1'
        $observation = [pscustomobject]@{
            ManifestPath = $manifest
            Scope = 'CurrentUser'
            FullVersion = '1.0.0'
        }
        $plan = [pscustomobject]@{
            ModuleName = 'FixtureModule'
            ModuleGuid = [guid]'11111111-1111-1111-1111-111111111111'
            Scope = 'CurrentUser'
            ObservedInstalledVersions = @($observation)
            TargetVersion = '2.0.0'
        }
        $script:operation = [pscustomobject]@{
            Plan = $plan
            RepositoryName = 'ApprovedFeed'
        }
        $script:candidate = [pscustomobject]@{
            InstalledLocation = $TestDrive
            Repository = 'ApprovedFeed'
        }
        $identity = [pscustomobject]@{
            Name = $plan.ModuleName
            Guid = $plan.ModuleGuid
            Version = [pscustomobject]@{ FullVersion = '1.0.0' }
        }
        Mock Get-ManifestIdentity { $identity } -ParameterFilter { $Path -ceq $manifest }
        Mock Get-NativeInstalledSource {
            [pscustomobject]@{
                Name = 'ApprovedFeed'
                Uri = 'https://feed.invalid'
            }
        }
    }
    It 'accepts the observed installed version rather than requiring the update target, with repository <Repository>' -ForEach @(
        @{ Repository = 'ApprovedFeed' }
        @{ Repository = 'approvedfeed' }
    ) {
        $candidate.Repository = $Repository
        @(Assert-NativeCandidate $operation $candidate).Count | Should -Be 0
    }
    It 'rejects a missing native candidate' {
        { Assert-NativeCandidate $operation $null } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects an installation without an exact observed manifest path' -ForEach @(
        @{ ObservedPath = 'elsewhere.psd1' }
        @{ ObservedPath = 'fixturemodule.psd1' }
    ) {
        $observation.ManifestPath = Join-Path $TestDrive $ObservedPath
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects ambiguous duplicate observations' {
        $plan.ObservedInstalledVersions = @($observation, $observation)
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects an observation outside the exact approved scope' -ForEach @(
        @{ Scope = 'AllUsers' }
        @{ Scope = 'currentuser' }
    ) {
        $observation.Scope = $Scope
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'rejects a manifest with another module name' {
        $identity.Name = 'OtherModule'
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
    It 'rejects a manifest version that differs from the observed installation' {
        $identity.Version.FullVersion = $plan.TargetVersion
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.VerificationFailed'
    }
    It 'rejects a manifest with another module GUID' {
        $identity.Guid = [guid]'22222222-2222-2222-2222-222222222222'
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.GuidMismatch'
        Should -Invoke Get-NativeInstalledSource -Times 0 -Exactly
    }
    It 'propagates rejection of unsafe installation paths' {
        Mock Assert-SafePath {
            Write-PMUError -Id 'PMU.UnsupportedInstallation' -Message 'Unsafe installation path.'
        }
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.UnsupportedInstallation'
    }
    It 'propagates native installed source validation failures' {
        Mock Get-NativeInstalledSource {
            Write-PMUError -Id 'PMU.SourceMismatch' -Message 'Unapproved native source URI.'
        }
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.SourceMismatch'
    }
    It 'rejects a candidate from another repository name' {
        $candidate.Repository = 'OtherFeed'
        { Assert-NativeCandidate $operation $candidate } | Should -Throw -ErrorId 'PMU.SourceMismatch'
    }
}
