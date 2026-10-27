function ConvertTo-UpdateDecision {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('UpToDate', 'UpdateAvailable', 'AlreadyInstalledRestartRequired', IgnoreCase = $false)]
        [string]$Disposition
    )

    $reason = switch -CaseSensitive ($Disposition) {
        'UpToDate' { 'No release newer than both actual active and installed versions is available.' }
        'UpdateAvailable' { 'An exact newer release is available.' }
        'AlreadyInstalledRestartRequired' { 'A newer version is already installed in the selected scope.' }
    }
    @{
        Available = $Disposition -ceq 'UpdateAvailable'
        Disposition = $Disposition
        Reason = $reason
        Restart = $Disposition -ceq 'AlreadyInstalledRestartRequired'
    }
}
