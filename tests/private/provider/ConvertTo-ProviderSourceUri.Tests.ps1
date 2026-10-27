BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'ConvertTo-ProviderSourceUri' -Tag 'PMUNative' {
    It 'retains the approved canonical URI and literal file path escaping' {
        $path = Join-Path $TestDrive 'feed #?% space'
        ConvertTo-ProviderSourceUri $path | Should -BeExactly ([uri]::new($path, [UriKind]::Absolute).AbsoluteUri.TrimEnd('/'))
        ConvertTo-ProviderSourceUri 'https://EXAMPLE.invalid:443/feed/' | Should -BeExactly 'https://example.invalid/feed'
    }
    It 'rejects relative paths and credential-bearing sources' -ForEach @(
        @{ Value = '../feed' }
        @{ Value = 'feed' }
        @{ Value = 'https://user:secret@example.invalid/feed' }
        @{ Value = 'https://example.invalid/feed?token=secret' }
    ) {
        { ConvertTo-ProviderSourceUri $Value } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
}
