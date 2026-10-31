BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Invoke-NativeWorker' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $script:context = [pscustomobject]@{ Operation = [pscustomobject]@{} }
        $script:messages = [Collections.Generic.List[object]]::new()
        $script:leaseEntered = $false
        Mock Initialize-NativeProvider {}
        Mock Assert-NativeWorkerGo {}
        Mock Invoke-NativeWorkerLease { $script:leaseEntered = $true }
        Mock Write-NativeWorkerMessage { $script:messages.Add($Message) }
    }

    It 'announces READY after provider setup and waits for permission before entering the lease' {
        Mock Assert-NativeWorkerGo {
            $script:messages.Count | Should -Be 1
            $script:messages[0].Phase | Should -BeExactly 'READY'
            $script:leaseEntered | Should -BeFalse
        }
        Invoke-NativeWorker $context
        $leaseEntered | Should -BeTrue
    }

    It 'reports provider setup failure without announcing READY or entering a lease' {
        Mock Initialize-NativeProvider {
            Write-PMUError 'PMU.SourceMismatch' 'The source changed.'
        }
        Invoke-NativeWorker $context
        $messages.Count | Should -Be 1
        $messages[0].Phase | Should -BeExactly 'RESULT'
        $messages[0].Success | Should -BeFalse
        $messages[0].ErrorId | Should -BeExactly 'PMU.SourceMismatch'
        $leaseEntered | Should -BeFalse
    }

    It 'reports rejected permission after READY without entering a lease' {
        Mock Assert-NativeWorkerGo {
            Write-PMUError 'PMU.PlanStale' 'The parent cancelled.'
        }
        Invoke-NativeWorker $context
        $messages.Count | Should -Be 2
        $messages[0].Phase | Should -BeExactly 'READY'
        $messages[1].Success | Should -BeFalse
        $messages[1].ErrorId | Should -BeExactly 'PMU.PlanStale'
        $leaseEntered | Should -BeFalse
    }

    It 'reports inspection staging failure without entering the installation handshake' -Tag 'PMUTargetManifest' {
        $context | Add-Member InspectManifest $true
        Mock Initialize-StagedPackage {
            Write-PMUError 'PMU.GuidMismatch' 'Wrong target.'
        }
        Invoke-NativeWorker $context
        $messages.Count | Should -Be 1
        $messages[0].ErrorId | Should -Be PMU.GuidMismatch
        $leaseEntered | Should -BeFalse
        Should -Invoke Assert-NativeWorkerGo -Times 0
    }
}
