function Write-ProviderError {
    param([System.Management.Automation.ErrorRecord]$Failure, [string]$DefaultId)
    $id = $DefaultId
    if ($Failure.Exception -is [UnauthorizedAccessException] -or $Failure.Exception.Message -match '(?i)access.+denied|permission denied') { $id = 'PMU.PermissionDenied' }
    if ($Failure.Exception.Message -match '(?i)\b401\b|\b403\b|unauthorized|authentication') { $id = 'PMU.AuthenticationFailed' }
    Write-PMUError $id 'The provider operation failed. Provider diagnostics were withheld to protect credentials.' 'Check repository authentication and scope permissions, then obtain a fresh plan. PMU never elevates or changes scope.'
}
