BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
    Set-Item Function:\Resolve-RepositoryTransportRoot { throw 'The isolated root mock is required.' }
}
Describe 'Open-RepositoryTransport' -Tag 'PMUUriBridge' {
    BeforeEach {
        $script:uriFixture = Initialize-PMUUriFixture $TestDrive
        Mock Resolve-RepositoryTransportRoot { $script:uriFixture.Root }
        Initialize-PMUUriReadMock
        Initialize-PMUUriRegisterMock
        Initialize-PMUUriUnregisterMock
    }
    Context 'Operation-scoped ownership' {
        It 'flushes a nonsecret receipt before registration and removes only its own entry on close' {
            $lease = Open-RepositoryTransport $uriFixture.Source
            $receipt = Get-Content $lease.ReceiptPath -Raw
            $receipt | Should -Not -Match 'https:|transport.invalid|PSCredential|SecureString'
            $lease.Name | Should -Match '^pmu-uri-[a-f0-9]{32}$'
            Close-RepositoryTransport $lease $null
            $uriFixture.Entries.Count | Should -Be 0
            Test-Path $lease.ReceiptPath | Should -BeFalse
            Should -Invoke Register-PSResourceRepository -Times 1 -ParameterFilter { -not $Force -and -not $Trusted -and -not $CredentialInfo }
        }
        It 'does not register or create state for an existing bound name' {
            $source = [pscustomobject]@{
                Name = 'OwnedFixture'
                Uri = $uriFixture.Source.Uri
                ApiVersion = 'V3'
                Trusted = $false
            }
            $lease = Open-RepositoryTransport $source
            $lease.Name | Should -Be 'OwnedFixture'
            Close-RepositoryTransport $lease $null
            Test-Path $uriFixture.Root | Should -BeFalse
            Should -Invoke Register-PSResourceRepository -Times 0
        }
        It 'does not adopt another living operation registration for the same URI' {
            $first = Open-RepositoryTransport $uriFixture.Source
            (Get-RepositorySnapshotByUri ([uri]$uriFixture.Source.Uri)).Name | Should -BeNullOrEmpty
            $second = Open-RepositoryTransport $uriFixture.Source
            $second.Name | Should -Not -Be $first.Name
            Close-RepositoryTransport $second $null
            $uriFixture.Entries.ContainsKey($first.Name) | Should -BeTrue
            Close-RepositoryTransport $first $null
        }
        It 'rejects a credential-bearing URI before any lock, receipt or registration' {
            $uriFixture.Source.Uri = 'https://user:secret@transport.invalid/v3/index.json'
            { Open-RepositoryTransport $uriFixture.Source } | Should -Throw -ErrorId 'PMU.InvalidRequest*'
            Test-Path $uriFixture.Root | Should -BeFalse
            Should -Invoke Register-PSResourceRepository -Times 0
        }
        It 'bounds cooperative lock contention across different repository requests' {
            $lock = Enter-RepositoryRegistryLock $uriFixture.Root
            try {
                { Open-RepositoryTransport $uriFixture.Source -TimeoutMilliseconds 50 } | Should -Throw -ErrorId 'PMU.LockTimeout*'
            } finally {
                $lock.Dispose()
            }
            Should -Invoke Register-PSResourceRepository -Times 0
        }
    }
    Context 'Durable stale ownership and cleanup errors' {
        It 'reaps only a matching registration whose recorded process is dead' {
            $first = Open-RepositoryTransport $uriFixture.Source
            $receipt = Get-Content $first.ReceiptPath -Raw | ConvertFrom-Json
            $receipt.OwnerPid = [int]::MaxValue
            [IO.File]::WriteAllText($first.ReceiptPath, (ConvertTo-Json $receipt -Compress))
            $second = Open-RepositoryTransport $uriFixture.Source
            $uriFixture.Entries.ContainsKey($first.Name) | Should -BeFalse
            Close-RepositoryTransport $second $null
        }
        It 'does not remove a stale name repointed by another writer' {
            $first = Open-RepositoryTransport $uriFixture.Source
            $receipt = Get-Content $first.ReceiptPath -Raw | ConvertFrom-Json
            $receipt.OwnerPid = [int]::MaxValue
            [IO.File]::WriteAllText($first.ReceiptPath, (ConvertTo-Json $receipt -Compress))
            $uriFixture.Entries[$first.Name].Uri = [uri]'https://unrelated.invalid/v3/index.json'
            { Open-RepositoryTransport $uriFixture.Source } | Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
            Should -Invoke Unregister-PSResourceRepository -Times 0
        }
        It 'does not delete unrelated prefix names without a receipt' {
            $name = "pmu-uri-$([guid]::NewGuid().ToString('N'))"
            $uriFixture.Entries[$name] = [pscustomobject]@{
                Name = $name
                Uri = [uri]'https://unrelated.invalid/v3/index.json'
                ApiVersion = 'Unknown'
                Trusted = $false
                Priority = 50
            }
            $lease = Open-RepositoryTransport $uriFixture.Source
            Close-RepositoryTransport $lease $null
            $uriFixture.Entries.ContainsKey($name) | Should -BeTrue
        }
        It 'does not discard an unregister failure or its ownership receipt' {
            $lease = Open-RepositoryTransport $uriFixture.Source
            Mock Unregister-PSResourceRepository { throw 'provider secret must not escape' }
            { Close-RepositoryTransport $lease $null } | Should -Throw -ErrorId 'PMU.RepositoryCleanupFailed*'
            Test-Path $lease.ReceiptPath | Should -BeTrue
        }
        It 'preserves the original safe failure and explicitly records a secondary cleanup failure' {
            $lease = Open-RepositoryTransport $uriFixture.Source
            Mock Unregister-PSResourceRepository { throw 'provider secret must not escape' }
            try {
                Write-PMUError 'PMU.AuthenticationFailed' 'Authentication failed safely.'
            } catch {
                $failure = $_
            }
            $caught = { Close-RepositoryTransport $lease $failure } | Should -Throw -ErrorId 'PMU.AuthenticationFailed*' -PassThru
            $caught.Exception.Data['PMU.RepositoryCleanupFailed'] | Should -BeTrue
            "$caught" | Should -Not -Match 'provider secret'
        }
        It 'cleans a post-register provider exception using the durable receipt' {
            Mock Register-PSResourceRepository {
                param(
                    $Name,
                    $Uri,
                    $ApiVersion = 'Unknown',
                    $Priority
                )

                $script:uriFixture.Entries[$Name] = [pscustomobject]@{
                    Name = $Name
                    Uri = [uri]$Uri
                    ApiVersion = "$ApiVersion"
                    Trusted = $false
                    Priority = $Priority
                }
                throw 'provider secret must not escape'
            }
            { Open-RepositoryTransport $uriFixture.Source } | Should -Throw -ErrorId 'PMU.RepositoryUnavailable*'
            $uriFixture.Entries.Count | Should -Be 0
            Should -Invoke Unregister-PSResourceRepository -Times 1
        }
    }
}
