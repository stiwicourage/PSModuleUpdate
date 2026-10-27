function Invoke-PMUProcessUpdate {
    param(
        [object]$Plan,
        [string]$Mode,
        [Management.Automation.PSModuleInfo]$Module
    )

    $result = $Plan | Install-PSModuleUpdate -Confirm:$false
    if ($Mode -eq 'Loaded') {
        if (-not [object]::ReferenceEquals($Module, (Get-Module FixtureModule))) {
            throw 'The loaded fixture module was unexpectedly replaced.'
        }
    }
    $result | ConvertTo-Json -Depth 6 -Compress
}
