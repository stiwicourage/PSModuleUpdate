function Invoke-PMULocalProviderProcess {
    param([string]$Root, [string]$ModulePath)
    $homePath = Join-Path $Root 'home'
    $null = New-Item $homePath -ItemType Directory -Force
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', "$PSScriptRoot/Invoke-PMULocalProviderFixture.ps1", '-Root', $Root, '-ModulePath', $ModulePath)) {
        $start.ArgumentList.Add($argument)
    }
    $start.Environment['HOME'] = $homePath
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    Receive-PMUChildProcess ([Diagnostics.Process]::Start($start))
}
