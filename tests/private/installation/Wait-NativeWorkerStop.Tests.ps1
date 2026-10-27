BeforeAll {
    . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1"
}

Describe 'Wait-NativeWorkerStop' -Tag 'PMU', 'PMUWorkerProtocol' {
    BeforeEach {
        $inputPipe = [IO.StringWriter]::new()
        $output = [IO.StringReader]::new('owned worker output')
        $process = [pscustomobject]@{
            StandardInput = $inputPipe
            StandardOutput = $output
            ExitCode = $null
            FinalExitCode = 0
        }
        $process | Add-Member ScriptMethod WaitForExit {
            $this.ExitCode = $this.FinalExitCode
        }
        $script:worker = [pscustomobject]@{
            Process = $process
            Errors = [Threading.Tasks.Task]::FromResult('owned worker diagnostics')
            ExitCode = $null
        }
    }

    AfterEach {
        $inputPipe.Dispose()
        $output.Dispose()
    }

    It 'closes input and waits for termination before recording exit code <ExitCode>' -ForEach @(
        @{ ExitCode = 0 }
        @{ ExitCode = 23 }
    ) {
        $process.FinalExitCode = $ExitCode
        @(Wait-NativeWorkerStop $worker).Count | Should -Be 0
        $worker.ExitCode | Should -Be $ExitCode
        { $inputPipe.Write('after-close') } | Should -Throw
    }

    It 'propagates error-stream collection failures instead of reporting successful completion' {
        $failure = [InvalidOperationException]::new('Owned error stream failed.')
        $worker.Errors = [Threading.Tasks.Task]::FromException[string]($failure)
        { Wait-NativeWorkerStop $worker } | Should -Throw '*Owned error stream failed*'
        $worker.ExitCode | Should -Be 0
    }
}
