function Write-PMUError {
    param(
        [string]$Id,
        [string]$Message,
        [string]$Guidance = 'Obtain a fresh plan after correcting the reported condition.'
    )

    $exception = [InvalidOperationException]::new($Message)
    $target = [pscustomobject]@{ RecoveryGuidance = $Guidance }
    throw [System.Management.Automation.ErrorRecord]::new($exception, $Id, 'InvalidOperation', $target)
}
