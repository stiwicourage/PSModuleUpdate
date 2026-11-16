function Initialize-PMULocalProviderStart {
    param(
        [string]$Root,
        [string]$ModulePath,
        [string]$FixtureScript
    )
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $FixtureScript, '-Root', $Root, '-ModulePath', $ModulePath)) {
        $start.ArgumentList.Add($argument)
    }
    Initialize-PMUFixtureHome $start $Root
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start
}

function Initialize-PMUFixtureHome {
    param(
        [Diagnostics.ProcessStartInfo]$Start,
        [string]$Root
    )
    $homePath = Join-Path $Root 'home'
    $null = New-Item $homePath -ItemType Directory -Force
    $Start.Environment['HOME'] = $homePath
    foreach ($entry in (Get-PMUFixtureHomeMap).GetEnumerator()) {
        $path = Join-Path $homePath $entry.Value
        $null = New-Item $path -ItemType Directory -Force
        $Start.Environment[$entry.Key] = $path
    }
}

function Get-PMUFixtureHomeMap {
    @{
        XDG_CONFIG_HOME = '.config'
        XDG_CACHE_HOME = '.cache'
        XDG_DATA_HOME = '.local/share'
        TMPDIR = 'tmp'
    }
}
