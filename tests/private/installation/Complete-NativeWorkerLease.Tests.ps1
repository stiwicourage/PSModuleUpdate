BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Complete-NativeWorkerLease' -Tag 'PMU', 'PMUWorkerCleanup' {
    BeforeEach {
        $script:originalLease = [IO.MemoryStream]::new()
        $script:originalLease.Dispose()
        $script:replacementLease = [IO.MemoryStream]::new()
        $script:operation = @{
            Lock = $script:originalLease
            LockPath = Join-Path $TestDrive 'original-parent.lock'
        }
        $process = [pscustomobject]@{ Disposed = $false }
        $process | Add-Member -MemberType ScriptMethod -Name Dispose -Value {
            $this.Disposed = $true
        }
        $script:worker = [pscustomobject]@{ Process = $process }
        $script:stopCompleted = $false
        Mock Wait-NativeWorkerStop {
            [object]::ReferenceEquals($Worker, $script:worker) | Should -BeTrue
            $script:stopCompleted = $true
        }
        Mock Enter-InstallationLock {
            $script:stopCompleted | Should -BeTrue
            $script:worker.Process.Disposed | Should -BeFalse
            $Path | Should -BeExactly $script:operation.LockPath
            $script:replacementLease
        }
    }

    AfterEach {
        $script:originalLease.Dispose()
        $script:replacementLease.Dispose()
    }

    It 'waits for worker stop before reacquiring the original parent lease and disposing the process' {
        Complete-NativeWorkerLease $operation $worker

        [object]::ReferenceEquals($operation.Lock, $replacementLease) | Should -BeTrue
        $operation.Lock.CanRead | Should -BeTrue
        $worker.Process.Disposed | Should -BeTrue
        Should -Invoke Enter-InstallationLock -Times 1 -Exactly
    }

    It 'reacquires the original parent lease and disposes the process when worker stop fails' {
        $script:stopException = [InvalidOperationException]::new('Worker stop fixture failure')
        Mock Wait-NativeWorkerStop {
            $script:stopCompleted = $true
            throw [Management.Automation.ErrorRecord]::new(
                $script:stopException, 'PMU.WorkerStopFailed', 'InvalidOperation', $null
            )
        }

        $failure = { Complete-NativeWorkerLease $operation $worker } |
            Should -Throw -ErrorId 'PMU.WorkerStopFailed' -PassThru

        [object]::ReferenceEquals($failure.Exception, $stopException) | Should -BeTrue
        [object]::ReferenceEquals($operation.Lock, $replacementLease) | Should -BeTrue
        $operation.Lock.CanRead | Should -BeTrue
        $worker.Process.Disposed | Should -BeTrue
    }

    It 'disposes the process and leaves no claimed parent lease when reacquisition fails' {
        Mock Enter-InstallationLock {
            $script:stopCompleted | Should -BeTrue
            $Path | Should -BeExactly $script:operation.LockPath
            Write-PMUError 'PMU.LockTimeout' 'Parent lease fixture failure'
        }

        { Complete-NativeWorkerLease $operation $worker } |
            Should -Throw -ErrorId 'PMU.LockTimeout'

        $operation.Lock | Should -BeNullOrEmpty
        $worker.Process.Disposed | Should -BeTrue
    }
}
