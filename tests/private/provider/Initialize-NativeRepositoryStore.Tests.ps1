BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module PowerShellGet -RequiredVersion 2.2.5
}

Describe 'Initialize-NativeRepositoryStore' -Tag 'PMURepositoryCharacterization' {
    BeforeEach {
        $destination = Join-Path $TestDrive 'modules'
        $script:operation = [pscustomobject]@{
            RepositoryName = 'ApprovedFeed'
            Plan = [pscustomobject]@{
                Scope = 'CurrentUser'
                DestinationRoot = $destination
            }
            NativeContext = [pscustomobject]@{
                Root = $TestDrive
                CurrentUserRoot = $destination
            }
        }
        $script:paths = [pscustomobject]@{
            Store = "$TestDrive/cache/repositories.xml"
            Settings = "$TestDrive/cache/settings.xml"
            Config = "$TestDrive/config"
            Temporary = "$TestDrive/tmp"
            CurrentUser = $destination
        }
        $script:repositories = @()
        Mock Get-NativeProviderPath { $script:paths }
        Mock PowerShellGet\Get-PSRepository { $script:repositories }
        Mock PowerShellGet\Unregister-PSRepository {}
    }

    It 'retains the approved name case-insensitively and removes only other owned registrations' {
        $script:repositories = @(
            [pscustomobject]@{ Name = 'ForeignFeed' }
            [pscustomobject]@{ Name = 'approvedfeed' }
        )

        Initialize-NativeRepositoryStore $operation | Should -BeTrue

        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'ForeignFeed' -and $ErrorAction -eq 'Stop'
        }
        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 1 -Exactly
    }

    It 'reports a missing approved registration after clearing an unrelated registration' {
        $script:repositories = @([pscustomobject]@{ Name = 'ForeignFeed' })

        Initialize-NativeRepositoryStore $operation | Should -BeFalse

        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'ForeignFeed'
        }
    }

    It 'reports an empty owned store without attempting removal' {
        Initialize-NativeRepositoryStore $operation | Should -BeFalse

        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 0 -Exactly
    }

    It 'rejects escaped storage or changed installation paths before native registration I/O' -ForEach @(
        @{ Field = 'Store' }
        @{ Field = 'Settings' }
        @{ Field = 'Config' }
        @{ Field = 'Temporary' }
        @{ Field = 'CurrentUser' }
    ) {
        $paths.$Field = "$TestDrive-neighbor/foreign"

        { Initialize-NativeRepositoryStore $operation } |
            Should -Throw -ErrorId 'PMU.UnsupportedProviderBehavior'

        Should -Invoke PowerShellGet\Get-PSRepository -Times 0 -Exactly
        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 0 -Exactly
        Test-Path -LiteralPath $paths.$Field | Should -BeFalse
    }

    It 'propagates a failed removal rather than reporting an initialized store' {
        $script:repositories = @([pscustomobject]@{ Name = 'ForeignFeed' })
        Mock PowerShellGet\Unregister-PSRepository { throw 'owned store is read-only' }

        { Initialize-NativeRepositoryStore $operation } |
            Should -Throw '*owned store is read-only*'
    }

    It 'stops after a repository enumeration error without treating partial results as an empty store' {
        Mock PowerShellGet\Get-PSRepository {
            [pscustomobject]@{ Name = 'ForeignFeed' }
            Write-Error 'owned store could not be read' -ErrorId 'PMUFixture.RepositoryReadFailed'
        }

        { Initialize-NativeRepositoryStore $operation } |
            Should -Throw -ErrorId 'PMUFixture.RepositoryReadFailed*'

        Should -Invoke PowerShellGet\Unregister-PSRepository -Times 0 -Exactly
    }
}
