function Write-NativeWorkerError {
    param([object]$Result)
    $id = 'PMU.InstallationFailed'
    if ($Result.ErrorId -match '^PMU\.[A-Za-z]+$') {
        $id = $Result.ErrorId
    }
    Write-PMUError $id 'The native update failed. Recoverable evidence was preserved.' 'Do not delete pending PMU transaction data. Correct the reported condition, then obtain a fresh plan to recover or retry.'
}
