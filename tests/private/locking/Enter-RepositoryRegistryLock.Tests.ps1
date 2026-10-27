BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Enter-RepositoryRegistryLock' -Tag 'PMUUriBridge' {
    Context 'Bounded independent registry lock' {
        It 'rejects a competing handle and permits acquisition after disposal' {
            $root = Join-Path $TestDrive 'registry'
            $first = Enter-RepositoryRegistryLock $root
            try {
                { Enter-RepositoryRegistryLock $root 50 } | Should -Throw -ErrorId 'PMU.LockTimeout*'
            } finally {
                $first.Dispose()
            }
            $next = Enter-RepositoryRegistryLock $root 50
            $next.CanWrite | Should -BeTrue
            $next.Dispose()
        }
    }
}
