BeforeAll {
    . "$PSScriptRoot/Receive-PMUChildProcess.ps1"
    . "$PSScriptRoot/Close-PMUChildProcess.ps1"
}

Describe 'Receive-PMUChildProcess redirected streams' -Tag 'PMU', 'PMUChildCapture' {
    BeforeEach {
        $script:start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
        foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command')) {
            $start.ArgumentList.Add($argument)
        }
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
    }

    It 'drains both full pipes without deadlocking and preserves output and a nonzero exit code' {
        $command = @'
[Console]::Out.Write('o' * 262144)
[Console]::Error.Write('e' * 262144)
exit 7
'@
        $start.ArgumentList.Add($command)
        $child = [Diagnostics.Process]::Start($start)
        try {
            $result = Receive-PMUChildProcess $child

            $result.ExitCode | Should -Be 7
            $result.Output | Should -BeExactly ('o' * 262144)
            $result.Error | Should -BeExactly ('e' * 262144)
        } finally {
            Close-PMUChildProcess $child
        }
    }

    It 'enforces an explicitly selected deadline and terminates only its fixture process tree' {
        $start.ArgumentList.Add('Start-Sleep -Seconds 2')
        $child = [Diagnostics.Process]::Start($start)
        try {
            { Receive-PMUChildProcess $child -TimeoutMilliseconds 100 } |
                Should -Throw '*Fixture child process timed out.*'
            $child.WaitForExit(5000) | Should -BeTrue
        } finally {
            Close-PMUChildProcess $child
        }
    }
}
