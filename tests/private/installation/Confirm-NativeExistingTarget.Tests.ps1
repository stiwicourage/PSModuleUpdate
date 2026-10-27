BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Confirm-NativeExistingTarget' -Tag 'PMU', 'PMUWorkerContracts' {
    BeforeEach {
        $script:operation = Initialize-PMURecoveryFixture $TestDrive
        $script:tree = @([pscustomobject]@{
                Path = 'approved-target'
                SHA256 = 'approved-hash'
            })
        Mock Assert-InstalledPackage {}
    }

    It 'persists verification state only after validating the existing target' {
        Confirm-NativeExistingTarget $operation $tree
        $saved = Get-Content -LiteralPath $operation.JournalPath -Raw | ConvertFrom-Json
        $saved.State | Should -BeExactly 'Verification'
        Should -Invoke Assert-InstalledPackage -Times 1 -Exactly -ParameterFilter {
            $Tree[0].SHA256 -ceq 'approved-hash'
        }
    }

    It 'leaves the pending journal unchanged when installed-tree verification fails' {
        $before = (Get-FileHash -LiteralPath $operation.JournalPath).Hash
        Mock Assert-InstalledPackage {
            Write-PMUError 'PMU.VerificationFailed' 'The installed tree changed.'
        }
        { Confirm-NativeExistingTarget $operation $tree } |
            Should -Throw -ErrorId 'PMU.VerificationFailed'
        (Get-FileHash -LiteralPath $operation.JournalPath).Hash | Should -BeExactly $before
    }
}
