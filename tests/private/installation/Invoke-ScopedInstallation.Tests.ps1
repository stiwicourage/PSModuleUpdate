BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-ScopedInstallation' -Tag 'PMU' {
    Context 'Scope lock lifetime' {
        It 'disposes the reacquired original-key lease rather than an obsolete pre-handoff handle' -Tag 'PMUNativeHandoff' {
            $script:initialLease = [IO.MemoryStream]::new()
            $script:reacquiredLease = [IO.MemoryStream]::new()
            Mock Initialize-ControlledDirectory {}
            Mock Enter-InstallationLock { $script:initialLease }
            Mock Invoke-LockedInstallation {
                $Operation.Lock.CanRead | Should -BeTrue
                $Operation.Lock.Dispose()
                $Operation.Lock = $script:reacquiredLease
            }
            $operation = @{
                DataRoot = $TestDrive
                WorkRoot = $TestDrive
                LockPath = "$TestDrive/lock"
            }
            Invoke-ScopedInstallation $operation
            $initialLease.CanRead | Should -BeFalse
            $reacquiredLease.CanRead | Should -BeFalse
        }
        It 'releases an acquired handle even when the locked workflow fails' {
            $script:lease = [IO.MemoryStream]::new()
            Mock Initialize-ControlledDirectory {}
            Mock Enter-InstallationLock { $script:lease }
            Mock Invoke-LockedInstallation { throw [InvalidOperationException]::new('fixture failure') }
            $operation = @{
                DataRoot = $TestDrive
                WorkRoot = $TestDrive
                LockPath = "$TestDrive/lock"
            }
            { Invoke-ScopedInstallation $operation } | Should -Throw '*fixture failure*'
            $lease.CanRead | Should -BeFalse
        }
    }
}
