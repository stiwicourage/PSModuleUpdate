BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-RepositoryUriHash' -Tag 'PMUUriBridge' {
    Context 'Nonsecret endpoint binding' {
        It 'hashes normalized URI identity and rejects embedded credentials' {
            Get-RepositoryUriHash ([uri]'https://transport.invalid/feed/') | Should -Be (Get-RepositoryUriHash ([uri]'https://transport.invalid/feed'))
            { Get-RepositoryUriHash ([uri]'https://user:private@transport.invalid/feed') } | Should -Throw -ErrorId 'PMU.InvalidRequest*'
        }
    }
}
