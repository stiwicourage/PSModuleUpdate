function Wait-NativeWorkerStop {
    param([object]$Worker)
    $Worker.Process.StandardInput.Close()
    $output = $Worker.Process.StandardOutput.ReadToEndAsync()
    # Never release exclusion by killing an active writer on a parent timeout.
    $Worker.Process.WaitForExit()
    $Worker.ExitCode = $Worker.Process.ExitCode
    $null = $output.GetAwaiter().GetResult()
    $null = $Worker.Errors.GetAwaiter().GetResult()
}
