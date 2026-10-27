BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Assert-NativeRepositoryBinding' -Tag 'PMURepositoryCharacterization' {
    BeforeEach {
        $script:operation = [pscustomobject]@{ RepositoryName = 'ApprovedFeed' }
        $script:repository = [pscustomobject]@{ InstallationPolicy = 'Trusted' }
        Mock Get-NativeRepositorySnapshot { $script:repository }
    }

    It 'accepts a validated trusted snapshot without emitting registration metadata' {
        @(Assert-NativeRepositoryBinding $operation).Count | Should -Be 0

        Should -Invoke Get-NativeRepositorySnapshot -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Operation, $script:operation)
        }
    }

    It 'rejects a changed or missing trust policy: <Policy>' -ForEach @(
        @{ Policy = 'Untrusted' }
        @{ Policy = 'trusted' }
        @{ Policy = $null }
    ) {
        $repository.InstallationPolicy = $Policy

        { Assert-NativeRepositoryBinding $operation } |
            Should -Throw -ErrorId 'PMU.RepositoryChanged'
    }

    It 'preserves source-validation failure instead of treating it as trusted binding' {
        Mock Get-NativeRepositorySnapshot {
            Write-PMUError 'PMU.SourceMismatch' 'The source no longer matches.'
        }

        { Assert-NativeRepositoryBinding $operation } |
            Should -Throw -ErrorId 'PMU.SourceMismatch'
    }
}
