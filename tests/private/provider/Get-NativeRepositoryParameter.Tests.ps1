BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Get-NativeRepositoryParameter' -Tag 'PMURepositoryCharacterization' {
    It 'keeps the approved source untrusted and omits an absent credential' {
        $operation = [pscustomobject]@{
            RepositoryName = 'ApprovedFeed'
            Plan = [pscustomobject]@{ RepositoryUri = 'https://feed.example.invalid/approved' }
            Credential = $null
        }

        $parameters = Get-NativeRepositoryParameter $operation

        $parameters.Name | Should -BeExactly 'ApprovedFeed'
        $parameters.SourceLocation | Should -BeExactly $operation.Plan.RepositoryUri
        $parameters.InstallationPolicy | Should -BeExactly 'Untrusted'
        $parameters.ErrorAction | Should -BeExactly 'Stop'
        $parameters.ContainsKey('Credential') | Should -BeFalse
        $parameters.Count | Should -Be 4
    }

    It 'decodes a file URI and preserves the supplied credential instance' {
        $location = Join-Path $TestDrive 'approved feed # percent%'
        $credential = [pscredential]::new('fixture-user', [Security.SecureString]::new())
        $operation = [pscustomobject]@{
            RepositoryName = 'LocalFeed'
            Plan = [pscustomobject]@{ RepositoryUri = ([uri]::new($location)).AbsoluteUri }
            Credential = $credential
        }

        $parameters = Get-NativeRepositoryParameter $operation

        $parameters.SourceLocation | Should -BeExactly $location
        [object]::ReferenceEquals($parameters.Credential, $credential) | Should -BeTrue
        $parameters.Count | Should -Be 5
    }
}
