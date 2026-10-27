BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Invoke-NativeHandoff' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $script:operation = Initialize-PMURecoveryFixture $TestDrive
        $script:snapshot = [pscustomobject]@{ Marker = 'selected-installation' }
        Mock Get-NativeSelectedSnapshot { $script:snapshot }
        Mock Initialize-Replacement {}
        Mock ConvertTo-NativeWorkerContext { [pscustomobject]@{ Marker = 'approved-worker' } }
        Mock Invoke-NativeWorkerProcess { [pscustomobject]@{ Success = $true } }
        Mock Assert-NativeWorkerResult {}
    }

    AfterEach {
        if ($operation.Lock) {
            $operation.Lock.Dispose()
        }
    }

    It 'does not start a worker without ownership of the original lock' {
        { Invoke-NativeHandoff $operation $false } | Should -Throw -ErrorId 'PMU.PlanStale'
        Should -Invoke Invoke-NativeWorkerProcess -Times 0
    }

    It 'rejects a plan without a newer target before starting a worker' {
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        $operation.Plan.UpdateAvailable = $false
        { Invoke-NativeHandoff $operation $false } | Should -Throw -ErrorId 'PMU.PlanStale'
        Should -Invoke Invoke-NativeWorkerProcess -Times 0
    }

    It 'returns verified staged-tree evidence after an authorized handoff' {
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        $expected = $operation.Journal.StagedTree | ConvertTo-Json -Depth 6
        $actual = Invoke-NativeHandoff $operation $false | ConvertTo-Json -Depth 6
        $actual | Should -BeExactly $expected
        Should -Invoke Assert-NativeWorkerResult -Times 1 -Exactly
    }

    It 'permits existing-target verification without authorizing a newer installation' {
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        $operation.Plan.UpdateAvailable = $false
        Invoke-NativeHandoff $operation $true | Should -Not -BeNullOrEmpty
        Should -Invoke Get-NativeSelectedSnapshot -Times 1 -Exactly -ParameterFilter { $AlreadyInstalled }
    }

    It 'propagates rejected worker evidence instead of returning the staged tree' {
        $operation.Lock = Enter-InstallationLock $operation.LockPath
        Mock Assert-NativeWorkerResult {
            Write-PMUError 'PMU.RecoveryRequired' 'The worker result is not owned.'
        }
        { Invoke-NativeHandoff $operation $false } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
    }
}
