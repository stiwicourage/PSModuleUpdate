BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Invoke-NativeWorkerLease' -Tag 'PMU', 'PMUNativeHandoff' {
    BeforeEach {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:workerContext = [pscustomobject]@{
            Operation = $operation
            ParentPid = $PID
            ParentStarted = Get-RepositoryProcessStart $PID
            Token = Get-NativeJournalToken $operation
        }
        $script:journalHash = (Get-FileHash $operation.JournalPath).Hash
    }
    It 'refuses mutation after the approving parent instance dies' {
        $workerContext.ParentStarted = 'different process start'
        { Invoke-NativeWorkerLease $workerContext } | Should -Throw -ErrorId 'PMU.PlanStale'
        (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $journalHash
        $lease = Enter-InstallationLock $operation.LockPath 50
        $lease.Dispose()
    }
    It 'refuses mutation when recovery or replacement won the parent-to-worker gap' -ForEach @(
        @{ Winner = 'Recovery' }
        @{ Winner = 'Replacement' }
    ) {
        if ($Winner -eq 'Recovery') {
            Write-RecoveryJournalState $operation.Journal 'RecoveryCompleted'
        } else {
            $operation.Journal.TransactionId = [guid]::NewGuid().ToString('N')
            Write-DurableJournal $operation.Journal
        }
        $expectedHash = (Get-FileHash $operation.JournalPath).Hash
        { Invoke-NativeWorkerLease $workerContext } | Should -Throw -ErrorId 'PMU.PlanStale'
        (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $expectedHash
        Test-Path $operation.BackupPath | Should -BeTrue
    }
    It 'uses the exact old-format original lock file rather than a secondary worker-only gate' {
        $legacyLease = [IO.File]::Open($operation.LockPath, 'OpenOrCreate', 'ReadWrite', 'None')
        try {
            { Invoke-NativeWorkerLease $workerContext } | Should -Throw -ErrorId 'PMU.LockTimeout'
            (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $journalHash
        } finally {
            $legacyLease.Dispose()
        }
    }
}
