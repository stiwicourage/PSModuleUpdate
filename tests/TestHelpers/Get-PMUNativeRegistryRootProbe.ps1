function Get-PMUNativeRegistryRootProbe {
    param([string]$HomeDirectory)
    $null = New-Item $HomeDirectory -ItemType Directory -Force
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command')) { $start.ArgumentList.Add($argument) }
    $source = [IO.Path]::GetFullPath("$PSScriptRoot/../../src").Replace("'", "''")
    $start.ArgumentList.Add(". '$source/private/shared/Assert-SafePath.ps1'; . '$source/private/locking/Resolve-RepositoryTransportRoot.ps1'; [pscustomobject]@{ Home = `$env:HOME; Root = Resolve-RepositoryTransportRoot } | ConvertTo-Json -Compress")
    $start.Environment['HOME'] = $HomeDirectory
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $result = Receive-PMUChildProcess ([Diagnostics.Process]::Start($start))
    if ($result.ExitCode -ne 0) { throw 'Read-only native registry-root probe failed.' }
    $result.Output | ConvertFrom-Json
}
