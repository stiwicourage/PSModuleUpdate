function Get-PMUTestProviderFailure {
    param(
        [string]$Id = 'PackageNotFound',
        [string]$Message = 'provider-secret-fixture credential-user-fixture',
        [System.Management.Automation.ErrorCategory]$Category = 'ObjectNotFound'
    )

    $exception = [InvalidOperationException]::new($Message)
    return [System.Management.Automation.ErrorRecord]::new($exception, $Id, $Category, $null)
}
