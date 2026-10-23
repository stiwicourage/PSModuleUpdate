# Cross-cutting source-only tests cover public plans, operation leases and provider routing; no real registry calls.
BeforeAll {
    . "$PSScriptRoot/../TestHelpers/Import-PMUTestSource.ps1"
    Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
    Set-Item Function:\Resolve-RepositoryTransportRoot { throw 'The isolated root mock is required.' }
}
Describe 'PMU temporary URI public contract' -Tag 'PMUUriBridge' {
    BeforeEach {
        $script:repositoryFixture = Initialize-PMURepositoryFixture $TestDrive
        Initialize-PMURepositoryMock
        Initialize-PMUProviderMock
        $script:uriFixture = Initialize-PMUUriFixture $TestDrive
        Mock Resolve-RepositoryTransportRoot { $script:uriFixture.Root }
        Initialize-PMUUriReadMock
        Initialize-PMUUriRegisterMock
        Initialize-PMUUriUnregisterMock
    }
    It 'plans from an unregistered URI and retains URI identity rather than its ephemeral name' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $uriFixture.Source.Uri -Policy @{ Channel = 'IncludePrerelease' }
        $plan.RepositoryName | Should -BeNullOrEmpty
        $plan.RepositoryUri | Should -Be $uriFixture.Source.Uri
        $plan.RepositoryApiVersion | Should -Be V3
        (ConvertTo-Json $plan -Depth 12) | Should -Not -Match 'pmu-uri-|OwnerPid|ReceiptPath|PSCredential'
        $uriFixture.Entries.Count | Should -Be 0
        Should -Invoke Register-PSResourceRepository -Times 1
        Should -Invoke Unregister-PSResourceRepository -Times 1
    }
    It 'durably binds native inferred API before using the lease and preserves exact API cleanup checks' {
        $lease = Open-RepositoryTransport $uriFixture.Source
        try {
            (Read-RepositoryReceipt $lease.ReceiptPath $lease.Root).ApiVersion | Should -Be V3
            $lease.Source.ApiVersion | Should -Be V3
            $uriFixture.Entries[$lease.Name].ApiVersion = 'V2'
            { Assert-OwnedRepositoryConfiguration $uriFixture.Entries[$lease.Name] $lease.Receipt } |
                Should -Throw -ErrorId 'PMU.RepositoryRecoveryRequired*'
            $uriFixture.Entries[$lease.Name].ApiVersion = 'V3'
        }
        finally { Close-RepositoryTransport $lease }
    }
    It 'does not register or rediscover an unregistered URI during Install WhatIf' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $uriFixture.Source.Uri -Policy @{ Channel = 'IncludePrerelease' }
        $result = $plan | Install-PSModuleUpdate -WhatIf
        $result.Outcome | Should -Be WhatIf
        Should -Invoke Register-PSResourceRepository -Times 1
        Should -Invoke Find-ProviderResource -Times 1
        Should -Invoke Save-ProviderResource -Times 0
    }
    It 'requires native approval and trust before creating an installation transport' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $uriFixture.Source.Uri -Policy @{ Channel = 'IncludePrerelease' }
        { $plan | Install-PSModuleUpdate -Confirm:$false } | Should -Throw -ErrorId 'PMU.RepositoryTrustRequired*'
        Should -Invoke Register-PSResourceRepository -Times 1
    }
    It 'uses a new URI-bound temporary name for approved install and cleans both operations' {
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $uriFixture.Source.Uri -Policy @{ Channel = 'IncludePrerelease' }
        $result = $plan | Install-PSModuleUpdate -Confirm:$false -TrustRepository
        $result.Outcome | Should -Be Installed
        @($uriFixture.Events | Where-Object { $_ -like 'Register:*' } | Select-Object -Unique).Count | Should -Be 2
        $uriFixture.Entries.Count | Should -Be 0
        Should -Invoke Register-PSResourceRepository -Times 2
        Should -Invoke Unregister-PSResourceRepository -Times 2
    }
    It 'forwards only independent per-call credentials to discovery, staging and installation' {
        $credential = [pscredential]::new('bridge-fixture-user', [securestring]::new())
        $plan = Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri $uriFixture.Source.Uri -Credential $credential -Policy @{ Channel = 'IncludePrerelease' }
        $result = $plan | Install-PSModuleUpdate -Credential $credential -Confirm:$false -TrustRepository
        foreach ($call in $repositoryFixture.Calls) { [object]::ReferenceEquals($call.Credential, $credential) | Should -BeTrue }
        @($repositoryFixture.Calls.Repository | Select-Object -Unique).Count | Should -Be 2
        ConvertTo-Json @($plan, $result) -Depth 12 | Should -Not -Match 'bridge-fixture-user|PSCredential|pmu-uri-'
        Should -Invoke Register-PSResourceRepository -Times 2 -ParameterFilter { -not $CredentialInfo }
    }
    It 'rejects embedded explicit URI credentials with secret-safe diagnostics before registration' {
        $failure = { Get-PSModuleUpdate -Module $repositoryFixture.Module -RepositoryUri 'https://user:fixture-secret@transport.invalid/v3/index.json' } |
            Should -Throw -ErrorId 'PMU.InvalidRequest*' -PassThru
        "$failure" | Should -Not -Match 'fixture-secret|user:'
        Should -Invoke Register-PSResourceRepository -Times 0
        Should -Invoke Find-ProviderResource -Times 0
    }
    It 'rejects credentials embedded in registered source metadata before using it' {
        $uriFixture.Entries['Leaky'] = [pscustomobject]@{ Name = 'Leaky'; Uri = [uri]'https://user:fixture-secret@transport.invalid/v3/index.json'; Trusted = $false; ApiVersion = 'V3'; Priority = 50 }
        $failure = { Get-PSModuleUpdate -Module $repositoryFixture.Module -Repository Leaky } | Should -Throw -ErrorId 'PMU.InvalidRequest*' -PassThru
        "$failure" | Should -Not -Match 'fixture-secret|user:'
        Should -Invoke Register-PSResourceRepository -Times 0
        Should -Invoke Find-ProviderResource -Times 0
    }
}
