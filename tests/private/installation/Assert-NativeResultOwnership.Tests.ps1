BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Assert-NativeResultOwnership' -Tag 'PMU', 'PMUWorkerContracts' {
    BeforeEach {
        $script:operation = [pscustomobject]@{}
        $script:context = [pscustomobject]@{
            Token = [pscustomobject]@{ TransactionId = 'approved-transaction' }
        }
        $script:ownedJournal = [pscustomobject]@{ State = 'Verification' }
        Mock Assert-NativeHandoffJournal { $script:ownedJournal }
    }

    It 'returns the validated journal for the approved transaction' {
        $result = [pscustomobject]@{ Token = $context.Token }
        $journal = Assert-NativeResultOwnership $operation $context $result
        $journal.State | Should -BeExactly 'Verification'
    }

    It 'rejects a missing result without reading pending transaction state' {
        { Assert-NativeResultOwnership $operation $context $null } |
            Should -Throw -ErrorId 'PMU.RecoveryRequired'
        Should -Invoke Assert-NativeHandoffJournal -Times 0
    }

    It 'rejects a result from another transaction before reading its journal' {
        $result = [pscustomobject]@{
            Token = [pscustomobject]@{ TransactionId = 'different-transaction' }
        }
        { Assert-NativeResultOwnership $operation $context $result } |
            Should -Throw -ErrorId 'PMU.PlanStale'
        Should -Invoke Assert-NativeHandoffJournal -Times 0
    }

    It 'validates parent transaction ownership before reporting a tokenless worker error' {
        $result = [pscustomobject]@{
            Token = $null
            ErrorId = 'PMU.SourceMismatch'
        }
        { Assert-NativeResultOwnership $operation $context $result } |
            Should -Throw -ErrorId 'PMU.SourceMismatch'
        Should -Invoke Assert-NativeHandoffJournal -Times 1 -Exactly -ParameterFilter {
            $Token.TransactionId -ceq 'approved-transaction'
        }
    }

    It 'preserves a stale-journal failure instead of replacing it with the worker error' {
        Mock Assert-NativeHandoffJournal {
            Write-PMUError 'PMU.PlanStale' 'Recovery acquired the transaction.'
        }
        $result = [pscustomobject]@{
            Token = $null
            ErrorId = 'PMU.InstallationFailed'
        }
        { Assert-NativeResultOwnership $operation $context $result } |
            Should -Throw -ErrorId 'PMU.PlanStale'
    }
}
