BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Invoke-OwnedNativeUpdate' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $operation = Initialize-PMURecoveryFixture $TestDrive
        $script:context = [pscustomobject]@{
            Operation = $operation
            AlreadyInstalled = $false
        }
        $script:approvedTree = @([pscustomobject]@{
                Path = 'verified-target'
                SHA256 = 'verified-hash'
            })
        Mock Initialize-StagedPackage { $script:approvedTree }
        Mock Assert-NativeSelectedInstallation {}
        Mock Confirm-NativeExistingTarget {}
        Mock Invoke-ProviderInstallation {}
    }

    It 'validates the selected installation before handling AlreadyInstalled=<AlreadyInstalled>' -ForEach @(
        @{ AlreadyInstalled = $false }
        @{ AlreadyInstalled = $true }
    ) {
        $context.AlreadyInstalled = $AlreadyInstalled
        $result = Invoke-OwnedNativeUpdate $context
        $result.Success | Should -BeTrue
        $result.Token.TransactionId | Should -BeExactly $operation.Journal.TransactionId
        $operation.Journal.StagedTree[0].SHA256 | Should -BeExactly 'verified-hash'
        Should -Invoke Confirm-NativeExistingTarget -Times ([int]$AlreadyInstalled) -Exactly
        Should -Invoke Invoke-ProviderInstallation -Times ([int](-not $AlreadyInstalled)) -Exactly
    }

    It 'returns an owned failure without installing when the selected installation changes' {
        Mock Assert-NativeSelectedInstallation {
            Write-PMUError 'PMU.PlanStale' 'The selected installation changed.'
        }
        $before = (Get-FileHash -LiteralPath $operation.JournalPath).Hash
        $result = Invoke-OwnedNativeUpdate $context
        $result.Success | Should -BeFalse
        $result.ErrorId | Should -BeExactly 'PMU.PlanStale'
        $result.Token.TransactionId | Should -BeExactly $operation.Journal.TransactionId
        (Get-FileHash -LiteralPath $operation.JournalPath).Hash | Should -BeExactly $before
        Should -Invoke Invoke-ProviderInstallation -Times 0
        Should -Invoke Confirm-NativeExistingTarget -Times 0
    }

    It 'preserves a staging failure without entering installed-tree validation' {
        Mock Initialize-StagedPackage {
            Write-PMUError 'PMU.SourceMismatch' 'The staged source changed.'
        }
        $result = Invoke-OwnedNativeUpdate $context
        $result.Success | Should -BeFalse
        $result.ErrorId | Should -BeExactly 'PMU.SourceMismatch'
        Should -Invoke Assert-NativeSelectedInstallation -Times 0
        Should -Invoke Invoke-ProviderInstallation -Times 0
    }

    It 'returns an owned installation error instead of a successful result' {
        Mock Invoke-ProviderInstallation {
            Write-PMUError 'PMU.VerificationFailed' 'The installed tree did not match.'
        }
        $result = Invoke-OwnedNativeUpdate $context
        $result.Success | Should -BeFalse
        $result.ErrorId | Should -BeExactly 'PMU.VerificationFailed'
        $result.Token.TransactionId | Should -BeExactly $operation.Journal.TransactionId
    }
}
