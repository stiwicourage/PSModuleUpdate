BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
}

Describe 'Get-NativeRepositorySnapshot' -Tag 'PMURepositoryCharacterization' {
    BeforeEach {
        $script:operation = [pscustomobject]@{
            RepositoryName = 'ApprovedFeed'
            Plan = [pscustomobject]@{ RepositoryUri = 'https://feed.example.invalid/approved' }
        }
        $script:repository = [pscustomobject]@{
            Name = 'approvedfeed'
            SourceLocation = 'https://feed.example.invalid/approved'
            InstallationPolicy = 'Untrusted'
            PublishLocation = 'https://feed.example.invalid/publish'
        }
        $script:repositories = @($repository)
        Mock Get-NativeProviderPath {}
        Mock Assert-NativeProviderPath {}
        Mock PowerShellGet\Get-PSRepository { $script:repositories }
    }

    It 'returns the original registration metadata after canonical source and case-insensitive name validation' {
        $repository.SourceLocation = 'https://FEED.example.invalid:443/approved/'

        $snapshot = Get-NativeRepositorySnapshot $operation

        [object]::ReferenceEquals($snapshot, $repository) | Should -BeTrue
        $snapshot.InstallationPolicy | Should -BeExactly 'Untrusted'
        $snapshot.PublishLocation | Should -BeExactly 'https://feed.example.invalid/publish'
    }

    It 'accepts the literal local path corresponding to the approved file URI' {
        $repository.SourceLocation = Join-Path $TestDrive 'approved feed # percent%'
        $operation.Plan.RepositoryUri = ([uri]::new($repository.SourceLocation)).AbsoluteUri

        $snapshot = Get-NativeRepositorySnapshot $operation

        [object]::ReferenceEquals($snapshot, $repository) | Should -BeTrue
    }

    It 'rejects a missing registration' {
        $script:repositories = @()

        { Get-NativeRepositorySnapshot $operation } |
            Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }

    It 'rejects additional registrations even when the approved source remains present' {
        $script:repositories += [pscustomobject]@{ Name = 'OtherFeed' }

        { Get-NativeRepositorySnapshot $operation } |
            Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }

    It 'rejects a changed repository name' {
        $repository.Name = 'OtherFeed'

        { Get-NativeRepositorySnapshot $operation } |
            Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }

    It 'rejects a source URI differing from the approved URI, including path case' -ForEach @(
        @{ Source = 'https://other.example.invalid/approved' }
        @{ Source = 'https://feed.example.invalid/Approved' }
    ) {
        $repository.SourceLocation = $Source

        { Get-NativeRepositorySnapshot $operation } |
            Should -Throw -ErrorId 'PMU.SourceMismatch'
    }

    It 'propagates native lookup failure instead of returning a snapshot' {
        Mock PowerShellGet\Get-PSRepository { throw 'owned store cannot be read' }

        { Get-NativeRepositorySnapshot $operation } |
            Should -Throw '*owned store cannot be read*'
    }
}
