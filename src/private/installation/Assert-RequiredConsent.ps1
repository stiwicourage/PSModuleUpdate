function Assert-RequiredConsent {
    param([bool]$Required, [bool]$Allowed, [string]$ErrorId, [string]$Message)
    if ($Required -and -not $Allowed) { Write-PMUError $ErrorId $Message }
}
