function Receive-PMUChildProcess {
    param(
        [Diagnostics.Process]$Process,
        [ValidateRange(1, 2147483647)][int]$TimeoutMilliseconds = 45000
    )
    $output = $Process.StandardOutput.ReadToEndAsync()
    $errorOutput = $Process.StandardError.ReadToEndAsync()
    if (-not $Process.WaitForExit($TimeoutMilliseconds)) {
        $Process.Kill($true)
        throw 'Fixture child process timed out.'
    }
    [pscustomobject]@{
        ExitCode = $Process.ExitCode
        Output = $output.GetAwaiter().GetResult()
        Error = $errorOutput.GetAwaiter().GetResult()
    }
}
