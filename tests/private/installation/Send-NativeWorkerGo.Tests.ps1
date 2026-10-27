BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Send-NativeWorkerGo' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $inputPipe = [pscustomobject]@{
            LockPath = $operation.LockPath
            Received = $null
            Lease = $null
            Closed = $false
        }
        $inputPipe | Add-Member ScriptMethod WriteLine {
            param($Value)

            $this.Lease = Enter-InstallationLock $this.LockPath 50
            $this.Received = $Value
        }
        $inputPipe | Add-Member ScriptMethod Close { $this.Closed = $true }
        $script:worker = [pscustomobject]@{ Process = [pscustomobject]@{ StandardInput = $inputPipe } }
    }

    AfterEach {
        if ($inputPipe.Lease) {
            $inputPipe.Lease.Dispose()
        }
        if ($operation.Lock) {
            $operation.Lock.Dispose()
        }
    }

    It 'releases the original lease before delivering GO and closing the input pipe' {
        $lease = Enter-InstallationLock $operation.LockPath
        $operation.Lock = $lease
        Send-NativeWorkerGo $operation $worker
        $lease.CanRead | Should -BeFalse
        $operation.Lock | Should -BeNullOrEmpty
        $inputPipe.Lease.CanRead | Should -BeTrue
        $inputPipe.Received | Should -BeExactly 'GO'
        $inputPipe.Closed | Should -BeTrue
    }

    It 'does not send permission when the parent does not own the original lease' {
        { Send-NativeWorkerGo $operation $worker } | Should -Throw -ErrorId 'PMU.PlanStale'
        $inputPipe.Received | Should -BeNullOrEmpty
        $inputPipe.Lease | Should -BeNullOrEmpty
        $inputPipe.Closed | Should -BeFalse
    }
}
