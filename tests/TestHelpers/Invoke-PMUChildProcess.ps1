function Invoke-PMUChildProcess {
    param(
        [string]$Root,
        [string]$Mode,
        [string]$Repository = 'OwnedFeed'
    )

    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', "$PSScriptRoot/Invoke-PMUProcessFixture.ps1", '-Root', $Root, '-Mode', $Mode, '-Repository', $Repository)) {
        $start.ArgumentList.Add($argument)
    }
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    [Diagnostics.Process]::Start($start)
}
