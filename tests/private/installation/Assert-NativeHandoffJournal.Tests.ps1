BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Assert-NativeHandoffJournal' -Tag 'PMUNative' {
    BeforeEach {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $operation.Journal.PSObject.Properties.Remove('TransactionId')
        $operation.Journal | Add-Member TransactionId ([guid]::NewGuid().ToString('N'))
        Write-DurableJournal $operation.Journal
        $script:handoffToken = @{
            TransactionId = $operation.Journal.TransactionId
            State = $operation.Journal.State
            SHA256 = (Get-FileHash $operation.JournalPath).Hash
        }
    }
    It 'accepts the exact transaction and phase only under the unchanged journal token' {
        (Assert-NativeHandoffJournal $operation $handoffToken).TransactionId | Should -BeExactly $handoffToken.TransactionId
    }
    It 'does not roll back or clean up when <Change> wins a handoff gap' -ForEach @(
        @{ Change = 'Recovery' }
        @{ Change = 'Instance' }
        @{ Change = 'Legacy' }
        @{ Change = 'Phase' }
    ) {
        switch ($Change) {
            Recovery {
                Write-RecoveryJournalState $operation.Journal 'RecoveryCompleted'
            }
            Instance {
                $operation.Journal.TransactionId = [guid]::NewGuid().ToString('N')
                Write-DurableJournal $operation.Journal
            }
            Legacy {
                $operation.Journal.PSObject.Properties.Remove('TransactionId')
                Write-DurableJournal $operation.Journal
            }
            Phase {
                Write-RecoveryJournalState $operation.Journal 'Verification'
            }
        }
        $before = (Get-FileHash $operation.JournalPath).Hash
        { Assert-NativeHandoffJournal $operation $handoffToken } | Should -Throw -ErrorId 'PMU.PlanStale'
        (Get-FileHash $operation.JournalPath).Hash | Should -BeExactly $before
        Test-Path $operation.BackupPath | Should -BeTrue
    }
}
