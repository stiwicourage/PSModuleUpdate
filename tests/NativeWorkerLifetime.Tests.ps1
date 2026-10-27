BeforeAll {
    . "$PSScriptRoot/TestHelpers/Import-PMUTestSource.ps1"
    . "$PSScriptRoot/TestHelpers/NativeWorkerLifetime.TestSupport.ps1"
    foreach ($source in Get-PMUTestSourcePath "$PSScriptRoot/TestHelpers/NativeWorkerLifetime.TestSupport.ps1") {
        . $source
    }
}

Describe 'Native worker cross-process installation ownership' -Tag 'PMU', 'PMUWorkerLifetime' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:operation = Initialize-PMURecoveryFixture $root
        $operation | Add-Member NativeContext ([pscustomobject]@{ Root = Join-Path $root 'native' })
        $script:journalHash = (Get-FileHash -LiteralPath $operation.JournalPath).Hash
        $script:lease = Enter-InstallationLock $operation.LockPath
        $script:probe = $null
        $script:probe = Invoke-PMUNativeLeaseProbe $operation $root
        (Receive-PMUNativeLeaseMessage $probe).Phase | Should -BeExactly 'READY'
    }

    AfterEach {
        if ($lease) {
            $lease.Dispose()
        }
        if ($probe) {
            Close-PMUChildProcess @($probe.Worker, $probe.Parent)
        }
    }

    It 'does not mutate when the approving process dies before an explicit GO' {
        $probe.Parent.Kill()
        $probe.Parent.WaitForExit(10000) | Should -BeTrue
        $probe.Worker.StandardInput.Close()

        $result = Receive-PMUNativeLeaseMessage $probe

        $result.Success | Should -BeFalse
        $result.ErrorId | Should -BeExactly 'PMU.PlanStale'
        (Get-FileHash -LiteralPath $operation.JournalPath).Hash | Should -BeExactly $journalHash
        Test-Path (Join-Path $operation.NativeContext.Root 'writer-finished') | Should -BeFalse
    }

    It 'rechecks approving-process identity after waiting for the original installation lock' {
        $probe.Worker.StandardInput.WriteLine('GO')
        $probe.Parent.Kill()
        $probe.Parent.WaitForExit(10000) | Should -BeTrue
        $lease.Dispose()
        $script:lease = $null

        $result = Receive-PMUNativeLeaseMessage $probe

        $result.Success | Should -BeFalse
        $result.ErrorId | Should -BeExactly 'PMU.PlanStale'
        (Get-FileHash -LiteralPath $operation.JournalPath).Hash | Should -BeExactly $journalHash
        Test-Path -LiteralPath $operation.BackupPath | Should -BeTrue
    }

    It 'refuses a stale handoff after <Winner> wins the lock gap' -ForEach @(
        @{ Winner = 'Recovery' }
        @{ Winner = 'Replacement' }
    ) {
        $probe.Worker.StandardInput.WriteLine('GO')
        if ($Winner -eq 'Recovery') {
            Write-RecoveryJournalState $operation.Journal 'RecoveryCompleted'
        } else {
            $operation.Journal.TransactionId = [guid]::NewGuid().ToString('N')
            Write-DurableJournal $operation.Journal
        }
        $expectedHash = (Get-FileHash -LiteralPath $operation.JournalPath).Hash
        $lease.Dispose()
        $script:lease = $null

        $result = Receive-PMUNativeLeaseMessage $probe

        $result.Success | Should -BeFalse
        $result.ErrorId | Should -BeExactly 'PMU.PlanStale'
        (Get-FileHash -LiteralPath $operation.JournalPath).Hash | Should -BeExactly $expectedHash
        Test-Path -LiteralPath $operation.BackupPath | Should -BeTrue
    }

    It 'keeps the original lock while a writer outlives its approving process and input pipe' {
        $lease.Dispose()
        $script:lease = $null
        $probe.Worker.StandardInput.WriteLine('GO')
        (Receive-PMUNativeLeaseMessage $probe).Phase | Should -BeExactly 'WRITING'
        $probe.Parent.Kill()
        $probe.Parent.WaitForExit(10000) | Should -BeTrue
        $probe.Worker.StandardInput.Close()

        { Enter-InstallationLock $operation.LockPath 100 } | Should -Throw -ErrorId 'PMU.LockTimeout'
        Test-Path (Join-Path $operation.NativeContext.Root 'writer-finished') | Should -BeFalse

        Set-Content -LiteralPath (Join-Path $operation.NativeContext.Root 'release-writer') -Value 'release'
        (Receive-PMUNativeLeaseMessage $probe).Success | Should -BeTrue
        $probe.Worker.WaitForExit(10000) | Should -BeTrue
        $probe.Worker.ExitCode | Should -Be 0
        Get-Content (Join-Path $operation.NativeContext.Root 'writer-finished') | Should -BeExactly 'complete'
        $recoveryLease = Enter-InstallationLock $operation.LockPath 100
        $recoveryLease.Dispose()
        (Get-FileHash -LiteralPath $operation.JournalPath).Hash | Should -BeExactly $journalHash
    }
}
