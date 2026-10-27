BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Invoke-NativeWorkerProcess' -Tag 'PMU', 'PMUWorkerCleanup' {
    BeforeEach {
        $script:parentLease = [IO.MemoryStream]::new()
        $script:operation = @{
            Lock = $null
            LockPath = Join-Path $TestDrive 'parent.lock'
        }
        $script:context = [pscustomobject]@{ Token = 'isolated-worker-token' }
        $script:response = [pscustomobject]@{ Phase = 'RESULT'; Outcome = 'Installed' }
        $process = [pscustomobject]@{ Disposed = $false }
        $process | Add-Member -MemberType ScriptMethod -Name Dispose -Value {
            $this.Disposed = $true
        }
        $script:worker = [pscustomobject]@{ Process = $process; ExitCode = $null }
        $script:workerExitCode = 0
        $script:workerStopped = $false
        Mock Invoke-NativeWorkerStart { $script:worker }
        Mock Invoke-NativeWorkerExchange { $script:response }
        Mock Wait-NativeWorkerStop {
            $Worker.ExitCode = $script:workerExitCode
            $script:workerStopped = $true
        }
        Mock Enter-InstallationLock {
            $script:workerStopped | Should -BeTrue
            $Path | Should -BeExactly $script:operation.LockPath
            $script:parentLease
        }
    }

    AfterEach {
        $script:parentLease.Dispose()
    }

    It 'returns the successful exchange response after restoring parent ownership and disposing the process' {
        $actual = @(Invoke-NativeWorkerProcess $operation $context)

        $actual.Count | Should -Be 1
        [object]::ReferenceEquals($actual[0], $response) | Should -BeTrue
        [object]::ReferenceEquals($operation.Lock, $parentLease) | Should -BeTrue
        $operation.Lock.CanRead | Should -BeTrue
        $worker.Process.Disposed | Should -BeTrue
        Should -Invoke Invoke-NativeWorkerStart -Times 1 -Exactly -ParameterFilter {
            [object]::ReferenceEquals($Operation, $script:operation) -and
            [object]::ReferenceEquals($Context, $script:context)
        }
    }

    It 'completes the lease and preserves the original exchange failure <FailureId>' -ForEach @(
        @{ FailureId = 'PMU.SourceMismatch' }
        @{ FailureId = 'Fixture.ExchangeFailed' }
    ) {
        $script:exchangeException = [InvalidOperationException]::new('Exchange fixture failure')
        $script:exchangeFailure = [Management.Automation.ErrorRecord]::new(
            $script:exchangeException, $FailureId, 'InvalidOperation', $null
        )
        $script:workerExitCode = 9
        Mock Invoke-NativeWorkerExchange { throw $script:exchangeFailure }

        $failure = { Invoke-NativeWorkerProcess $operation $context } |
            Should -Throw -ErrorId $FailureId -PassThru

        [object]::ReferenceEquals($failure.Exception, $exchangeException) | Should -BeTrue
        [object]::ReferenceEquals($operation.Lock, $parentLease) | Should -BeTrue
        $operation.Lock.CanRead | Should -BeTrue
        $worker.Process.Disposed | Should -BeTrue
    }

    It 'rejects a completed exchange with an unsuccessful worker exit without emitting its response' {
        $script:workerExitCode = 17
        $emitted = [Collections.Generic.List[object]]::new()

        $failure = {
            Invoke-NativeWorkerProcess $operation $context |
                ForEach-Object { $emitted.Add($_) }
        } | Should -Throw -ErrorId 'PMU.RecoveryRequired' -PassThru

        $failure.Exception.Message | Should -Match 'Pending state was preserved'
        $emitted.Count | Should -Be 0
        [object]::ReferenceEquals($operation.Lock, $parentLease) | Should -BeTrue
        $worker.Process.Disposed | Should -BeTrue
    }
}
