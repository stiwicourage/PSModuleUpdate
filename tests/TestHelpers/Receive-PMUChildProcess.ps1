function Receive-PMUChildProcess {
    param([Diagnostics.Process]$Process)
    if (-not $Process.WaitForExit(45000)) {
        $Process.Kill($true)
        throw 'Fixture child process timed out.'
    }
    [pscustomobject]@{ ExitCode = $Process.ExitCode; Output = $Process.StandardOutput.ReadToEnd(); Error = $Process.StandardError.ReadToEnd() }
}
