BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . "$root/src/private/shared/Write-PMUError.ps1"
    . "$root/src/private/repository/Assert-RepositoryUri.ps1"
}
Describe 'Assert-RepositoryUri' -Tag 'PMU' {
    It 'normalizes a safe endpoint and rejects credential-bearing endpoints' {
        Assert-RepositoryUri ([uri]'https://example.invalid/feed/') | Should -Be 'https://example.invalid/feed'
        { Assert-RepositoryUri ([uri]'https://user:secret@example.invalid/feed') } | Should -Throw -ErrorId 'PMU.InvalidRequest'
    }
}
