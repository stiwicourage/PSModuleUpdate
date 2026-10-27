BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Restore-NativeParentLease' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $script:operation = Initialize-PMURecoveryFixture $TestDrive
    }

    AfterEach {
        if ($operation.Lock) {
            $operation.Lock.Dispose()
        }
    }

    It 'reacquires the original installation lock when the parent no longer owns it' {
        Restore-NativeParentLease $operation
        $operation.Lock.Name | Should -BeExactly $operation.LockPath
        $operation.Lock.CanRead | Should -BeTrue
        { Enter-InstallationLock $operation.LockPath 50 } | Should -Throw -ErrorId 'PMU.LockTimeout'
    }

    It 'retains an already owned original lease rather than replacing it' {
        $lease = Enter-InstallationLock $operation.LockPath
        $operation.Lock = $lease
        Restore-NativeParentLease $operation
        [object]::ReferenceEquals($operation.Lock, $lease) | Should -BeTrue
        $lease.CanRead | Should -BeTrue
    }

    It 'replaces a disposed lease with ownership of the original lock' {
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        $operation.Lock.Dispose()
        Restore-NativeParentLease $operation
        $operation.Lock.Name | Should -BeExactly $operation.LockPath
        $operation.Lock.CanRead | Should -BeTrue
    }

    It 'rejects a live lease for another file instead of treating it as ownership' {
        $other = Join-Path $TestDrive 'another-operation.lock'
        $operation.Lock = [IO.File]::Open($other, 'OpenOrCreate', 'ReadWrite', 'None')
        { Restore-NativeParentLease $operation } | Should -Throw -ErrorId 'PMU.PlanStale'
        $operation.Lock.Name | Should -BeExactly $other
    }
}
