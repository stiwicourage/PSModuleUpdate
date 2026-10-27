function Invoke-PMULocalProviderProcess {
    param(
        [string]$Root,
        [string]$ModulePath
    )

    $homePath = Join-Path $Root 'home'
    $null = New-Item $homePath -ItemType Directory -Force
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', "$PSScriptRoot/Invoke-PMULocalProviderFixture.ps1", '-Root', $Root, '-ModulePath', $ModulePath)) {
        $start.ArgumentList.Add($argument)
    }
    $start.Environment['HOME'] = $homePath
    foreach ($entry in @{
            XDG_CONFIG_HOME = '.config'
            XDG_CACHE_HOME = '.cache'
            XDG_DATA_HOME = '.local/share'
            TMPDIR = 'tmp'
        }.GetEnumerator()) {
        $path = Join-Path $homePath $entry.Value
        $null = New-Item $path -ItemType Directory -Force
        $start.Environment[$entry.Key] = $path
    }
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    # This fixture performs five sequential native updates, not one process probe.
    Receive-PMUChildProcess ([Diagnostics.Process]::Start($start)) -TimeoutMilliseconds 150000
}
