BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Undo-OwnedRepositoryRegistration' -Tag 'PMUUriBridge' {
    BeforeEach {
        $script:lease = [pscustomobject]@{
            ReceiptPath = 'receipt-path'
            Receipt = [pscustomobject]@{ RegistrationName = 'owned' }
        }
        $script:failure = [Management.Automation.ErrorRecord]::new(
            [InvalidOperationException]::new('registration failed'),
            'RegistrationFailure',
            'InvalidOperation',
            $null
        )
        Mock Clear-OwnedRepositoryReceipt {}
        Mock Write-RepositoryCleanupFailure {}
    }
    It 'rethrows the original failure without cleanup when the receipt is absent' {
        Mock Test-Path { $false }
        try {
            Undo-OwnedRepositoryRegistration $lease $failure
        } catch {
            $caught = $_
        }
        [object]::ReferenceEquals($caught.Exception, $failure.Exception) | Should -BeTrue
        Should -Invoke Clear-OwnedRepositoryReceipt -Times 0
    }
    It 'cleans only the matching receipt entry' {
        Mock Test-Path { $true }
        Undo-OwnedRepositoryRegistration $lease $failure
        Should -Invoke Clear-OwnedRepositoryReceipt -Times 1 -ParameterFilter {
            $Entry.Path -eq $lease.ReceiptPath -and
            [object]::ReferenceEquals($Entry.Receipt, $lease.Receipt)
        }
    }
    It 'reports the original registration failure when cleanup fails' {
        Mock Test-Path { $true }
        Mock Clear-OwnedRepositoryReceipt { throw 'cleanup failed' }
        Undo-OwnedRepositoryRegistration $lease $failure
        Should -Invoke Write-RepositoryCleanupFailure -Times 1 -ParameterFilter { [object]::ReferenceEquals($Original, $failure) }
    }
}
