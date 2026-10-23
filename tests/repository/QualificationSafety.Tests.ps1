# Cross-cutting qualification guards: these own only disposable harness state, not PMU behavior.
BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$root/scripts/qualification/QualificationSafety.ps1"
    . "$root/scripts/qualification/QualificationSession.ps1"
}

Describe 'Repository qualification safety' -Tag 'RepositoryQualification' {
    It 'requires explicit live and shared-store authorization' {
        { Assert-QualificationAuthorization $false $true } | Should -Throw '*opt-in*'
        { Assert-QualificationAuthorization $true $false } | Should -Throw '*store*'
        { Assert-QualificationAuthorization $true $true } | Should -Not -Throw
    }

    It 'accepts only HTTPS endpoints without embedded authentication or query state' {
        Assert-QualificationEndpoint 'https://api.nuget.org/v3/index.json' | Should -BeNullOrEmpty
        foreach ($uri in @('http://example.test', 'https://u:p@example.test', 'https://example.test/?token=x', 'https://example.test/#x')) {
            { Assert-QualificationEndpoint $uri } | Should -Throw '*endpoint*'
        }
    }

    It 'requires the actual provider destination to be inside the disposable home' {
        Assert-QualificationDestination "$TestDrive/home/.local/share/powershell/Modules" "$TestDrive/home" | Should -BeNullOrEmpty
        { Assert-QualificationDestination "$TestDrive/home-other/Modules" "$TestDrive/home" } | Should -Throw '*destination*'
        { Assert-QualificationDestination "$TestDrive/home" "$TestDrive/home" } | Should -Throw '*destination*'
    }

    It 'accepts canonical native child paths and normalizes alternate separators when supported' {
        $homePath = [IO.Path]::GetFullPath((Join-Path $TestDrive 'home'))
        $child = Join-Path $homePath 'Modules'
        Assert-QualificationDestination $child $homePath | Should -BeNullOrEmpty
        $alternateHome = $homePath.Replace([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        Assert-QualificationDestination $child "$alternateHome/" | Should -BeNullOrEmpty
    }

    It 'rejects native sibling prefixes and canonical traversal out of the home' {
        $homePath = Join-Path $TestDrive 'home'
        { Assert-QualificationDestination (Join-Path "$homePath-other" 'Modules') $homePath } | Should -Throw '*destination*'
        { Assert-QualificationDestination "$homePath/../outside/Modules" $homePath } | Should -Throw '*destination*'
        { Assert-QualificationDestination "$homePath/Modules/.." $homePath } | Should -Throw '*destination*'
    }

    It 'rejects symlinked disposable roots before installation' {
        New-Item "$TestDrive/real" -ItemType Directory | Out-Null
        New-Item "$TestDrive/linked" -ItemType SymbolicLink -Target "$TestDrive/real" | Out-Null
        { Assert-QualificationDestination "$TestDrive/linked/Modules" "$TestDrive/linked" } | Should -Throw '*link*'
    }

    It 'detects changes to existing registrations regardless of enumeration order' {
        $before = @('A|https://a.test/|False', 'B|https://b.test/|True')
        Assert-QualificationRepositoryState $before @($before[1], $before[0]) | Should -BeNullOrEmpty
        { Assert-QualificationRepositoryState $before @($before[0]) } | Should -Throw '*registration*'
    }

    It 'rejects credential-bearing result fields without serializing their values' {
        Assert-QualificationPublicObject ([pscustomobject]@{ ModuleName = 'Example'; RepositoryUri = [uri]'https://example.test' }) | Should -BeNullOrEmpty
        $secret = [pscredential]::new('test-user', [securestring]::new())
        { Assert-QualificationPublicObject ([pscustomobject]@{ Nested = @{ Credential = $secret } }) } | Should -Throw '*credential*'
        { Assert-QualificationPublicObject ([pscustomobject]@{ RepositoryUri = [uri]'https://u:p@example.test' }) } | Should -Throw '*endpoint*'
    }

    It 'does not treat a stale built module as current source qualification' {
        $sourceRoot = New-Item "$TestDrive/source" -ItemType Directory
        Set-Content "$sourceRoot/Get-Example.ps1" 'function Get-Example { 42 }'
        Set-Content "$TestDrive/module.psm1" 'function Get-Example { 41 }'
        { Assert-QualificationBuild "$TestDrive/module.psm1" $sourceRoot } | Should -Throw '*stale*'
        Set-Content "$TestDrive/module.psm1" 'function Get-Example { 42 }'
        Assert-QualificationBuild "$TestDrive/module.psm1" $sourceRoot | Should -BeNullOrEmpty
    }

    It 'compares empty registration stores and rejects additions' {
        Assert-QualificationRepositoryState @() @() | Should -BeNullOrEmpty
        { Assert-QualificationRepositoryState @() @('Unexpected') } | Should -Throw '*registration*'
    }

    It 'does not send an inherited private-feed credential to public qualification endpoints' {
        $previous = $env:ADO_PAT
        try {
            $env:ADO_PAT = 'qualification-only-not-a-secret'
            Get-QualificationCredential 'Gallery' | Should -BeNullOrEmpty
        } finally { $env:ADO_PAT = $previous }
    }

    It 'accepts only the exact explicitly approved built artifact while source work continues' {
        Set-Content "$TestDrive/approved.psm1" 'function Get-Approved { 42 }'
        $hash = (Get-FileHash "$TestDrive/approved.psm1" -Algorithm SHA256).Hash
        { Assert-QualificationModuleHash "$TestDrive/approved.psm1" $hash } | Should -Not -Throw
        { Assert-QualificationModuleHash "$TestDrive/approved.psm1" ('0' * 64) } | Should -Throw '*approved*'
    }
}
