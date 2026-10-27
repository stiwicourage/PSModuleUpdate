BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Invoke-NativeWorkerExchange' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $script:operation = [pscustomobject]@{}
        $script:goSent = $false
        Mock Send-NativeWorkerGo { $script:goSent = $true }
    }

    It 'returns an early worker failure without granting mutation permission' {
        $reader = [IO.StringReader]::new('PMU_NATIVE:{"Phase":"RESULT","Success":false}')
        $worker = [pscustomobject]@{ Process = [pscustomobject]@{ StandardOutput = $reader } }
        try {
            $result = Invoke-NativeWorkerExchange $operation $worker
            $result.Success | Should -BeFalse
            $goSent | Should -BeFalse
        } finally {
            $reader.Dispose()
        }
    }

    It 'grants mutation only after READY and returns the subsequent result' {
        $protocol = @'
PMU_NATIVE:{"Phase":"READY"}
PMU_NATIVE:{"Phase":"RESULT","Success":true}
'@
        $reader = [IO.StringReader]::new($protocol)
        $worker = [pscustomobject]@{ Process = [pscustomobject]@{ StandardOutput = $reader } }
        try {
            $result = Invoke-NativeWorkerExchange $operation $worker
            $goSent | Should -BeTrue
            $result.Phase | Should -BeExactly 'RESULT'
            $result.Success | Should -BeTrue
        } finally {
            $reader.Dispose()
        }
    }

    It 'rejects an unexpected ready phase without granting mutation: <Phase>' -ForEach @(
        @{ Phase = 'ready' }
        @{ Phase = 'GO' }
        @{ Phase = 'UNKNOWN' }
    ) {
        $reader = [IO.StringReader]::new("PMU_NATIVE:{`"Phase`":`"$Phase`"}")
        $worker = [pscustomobject]@{ Process = [pscustomobject]@{ StandardOutput = $reader } }
        try {
            { Invoke-NativeWorkerExchange $operation $worker } | Should -Throw -ErrorId 'PMU.PlanStale'
            $goSent | Should -BeFalse
        } finally {
            $reader.Dispose()
        }
    }

    It 'reports a worker that stops after READY instead of returning a successful result' {
        $reader = [IO.StringReader]::new('PMU_NATIVE:{"Phase":"READY"}')
        $worker = [pscustomobject]@{ Process = [pscustomobject]@{ StandardOutput = $reader } }
        try {
            { Invoke-NativeWorkerExchange $operation $worker } | Should -Throw -ErrorId 'PMU.RecoveryRequired'
            $goSent | Should -BeTrue
        } finally {
            $reader.Dispose()
        }
    }
}
