BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeWorkerResult' -Tag 'PMU', 'PMUNativeHandoff' {
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
}
