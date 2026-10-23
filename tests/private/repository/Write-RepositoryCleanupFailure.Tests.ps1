BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Write-RepositoryCleanupFailure' -Tag 'PMUUriBridge' {
    Context 'Explicit cleanup failure' {
        It 'does not expose an unaudited original provider exception' {
            try { throw 'private provider URL or secret' } catch { $failure = $_ }
            $caught = { Write-RepositoryCleanupFailure $failure } | Should -Throw -ErrorId 'PMU.RepositoryCleanupFailed*' -PassThru
            "$caught" | Should -Not -Match 'private provider'
        }
    }
}
