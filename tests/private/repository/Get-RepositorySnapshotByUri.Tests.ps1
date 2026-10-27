BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
}
Describe 'Get-RepositorySnapshotByUri' -Tag 'PMU', 'PMURepositoryUri' {
    Context 'Exact registered URI selection' {
        BeforeEach {
            $script:uriRepositories = @((Get-PMURepositoryEntry).Values)
            Mock Get-PSResourceRepository {
                if ($Name) {
                    return $script:uriRepositories | Where-Object Name -EQ $Name
                }
                $script:uriRepositories
            }
            Mock Register-PSResourceRepository { throw 'Registration mutation is prohibited.' }
            Mock Unregister-PSResourceRepository { throw 'Registration mutation is prohibited.' }
        }
        It 'binds exactly one registered name to the requested endpoint without writes' {
            $snapshot = Get-RepositorySnapshotByUri ([uri]'https://private.invalid/v3/index.json')
            $snapshot.Name | Should -Be 'PrivateFixture'
            $snapshot.Trusted | Should -BeFalse
            Should -Invoke Register-PSResourceRepository -Times 0
            Should -Invoke Unregister-PSResourceRepository -Times 0
        }
        It 'describes an unregistered URI without selecting a different feed or mutating the store' {
            $source = Get-RepositorySnapshotByUri ([uri]'https://missing.invalid/v3/index.json')
            $source.Name | Should -BeNullOrEmpty
            $source.Uri | Should -Be 'https://missing.invalid/v3/index.json'
            Should -Invoke Register-PSResourceRepository -Times 0
        }
        It 'rejects duplicate endpoint registrations rather than choosing by priority or trust' {
            $script:uriRepositories += [pscustomobject]@{
                Name = 'AliasFixture'
                Uri = $uriRepositories[1].Uri
                ApiVersion = 'V3'
                Trusted = $true
            }
            { Get-RepositorySnapshotByUri $uriRepositories[1].Uri } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable'
        }
        It 'rejects a policy endpoint that conflicts with the selected URI' {
            { Get-RepositorySnapshotByUri $uriRepositories[0].Uri $uriRepositories[1].Uri } | Should -Throw -ErrorId 'PMU.RepositoryChanged'
        }
    }
}
