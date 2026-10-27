BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeWorkerResult' -Tag 'PMU', 'PMUNativeHandoff', 'PMUCoverageFollowUp' {
    BeforeEach {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:resultContext = [pscustomobject]@{ Token = Get-NativeJournalToken $operation }
        Write-RecoveryJournalState $operation.Journal 'Verification'
        $script:workerResult = [pscustomobject]@{
            Success = $true
            Token = Get-NativeJournalToken $operation
            ErrorId = $null
        }
    }
    It 'requires a reacquired original lock before interpreting the worker result' {
        { Assert-NativeWorkerResult $operation $resultContext $workerResult } | Should -Throw -ErrorId 'PMU.PlanStale'
    }
    It 'accepts an exact successful worker token only while owning the original lock' {
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        try {
            Assert-NativeWorkerResult $operation $resultContext $workerResult
            $operation.Journal.State | Should -BeExactly 'Verification'
        } finally {
            $operation.Lock.Dispose()
        }
    }
    It 'does not perform stale rollback or cleanup if another recovery won the worker-to-parent gap' {
        Write-RecoveryJournalState $operation.Journal 'Completed'
        $expectedHash = (Get-FileHash $operation.JournalPath).Hash
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        try {
            { Assert-NativeWorkerResult $operation $resultContext $workerResult } | Should -Throw -ErrorId 'PMU.PlanStale'
            (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $expectedHash
            Test-Path $operation.BackupPath | Should -BeTrue
        } finally {
            $operation.Lock.Dispose()
        }
    }
    Context 'Owned worker result failures' {
        BeforeEach {
            $operation.Lock = Enter-InstallationLock $operation.LockPath
        }
        AfterEach {
            $operation.Lock.Dispose()
        }

        It 'propagates an owned worker failure without discarding recoverable evidence' {
            $workerResult.Success = $false
            $workerResult.ErrorId = 'PMU.InstallationFailed'
            $expectedHash = (Get-FileHash $operation.JournalPath).Hash
            { Assert-NativeWorkerResult $operation $resultContext $workerResult } |
                Should -Throw -ErrorId 'PMU.InstallationFailed' -ExpectedMessage 'The native update failed. Recoverable evidence was preserved.'
            (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $expectedHash
            Test-Path $operation.BackupPath | Should -BeTrue
        }

        It 'rejects a matching successful token when verification has been superseded' {
            Write-RecoveryJournalState $operation.Journal 'RecoveryCompleted'
            $workerResult.Token = Get-NativeJournalToken $operation
            $expectedHash = (Get-FileHash $operation.JournalPath).Hash
            { Assert-NativeWorkerResult $operation $resultContext $workerResult } |
                Should -Throw -ErrorId 'PMU.PlanStale' -ExpectedMessage 'The native verification phase was superseded.'
            (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $expectedHash
        }
    }
}
