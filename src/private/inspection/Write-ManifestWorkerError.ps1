function Write-ManifestWorkerError {
    param([object]$Result)
    $id = 'PMU.InstallationFailed'
    if ($Result.ErrorId -match '^PMU\.[A-Za-z]+$') {
        $id = $Result.ErrorId
    }
    Write-PMUError $id 'The target manifest could not be inspected. Provider diagnostics were withheld to protect credentials.' 'Check the source and prerequisites, then obtain a fresh plan.'
}
