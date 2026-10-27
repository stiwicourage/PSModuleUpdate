function Initialize-PMUNativeLeaseModule {
    param([string]$Root)

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $entry = Join-Path $projectRoot 'src/private/installation/Invoke-NativeWorker.ps1'
    $sources = @($entry) + @(Get-PMUTestSourcePath $entry)
    $imports = $sources | ForEach-Object { ". '$($_.Replace("'", "''"))'" }
    $fixture = @'
${function:Initialize-NativeProvider} = {
    param([object]$Operation)
}

${function:Assert-NativeSelectedInstallation} = {
    param([object]$Context)
}

# Only the provider boundary is simulated; ownership and journal checks stay real.
${function:Invoke-OwnedNativeUpdate} = {
    param([object]$Context)

    $root = $Context.Operation.NativeContext.Root
    $release = Join-Path $root 'release-writer'
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    Write-NativeWorkerMessage ([pscustomobject]@{ Phase = 'WRITING' })
    while (-not (Test-Path -LiteralPath $release)) {
        if ([DateTime]::UtcNow -gt $deadline) {
            throw 'Disposable native writer was not released.'
        }
        Start-Sleep -Milliseconds 20
    }
    [IO.File]::WriteAllText((Join-Path $root 'writer-finished'), 'complete')
    [pscustomobject]@{ Phase = 'RESULT'; Success = $true }
}

Export-ModuleMember -Function @()
'@
    $path = Join-Path $Root 'lease-worker.psm1'
    Set-Content -LiteralPath $path -Value (($imports -join "`n") + "`n" + $fixture) -Encoding utf8
    $path
}

function Invoke-PMUNativeLeaseApprover {
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command', '$null = [Console]::In.ReadLine()')) {
        $start.ArgumentList.Add($argument)
    }
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    [Diagnostics.Process]::Start($start)
}

function Invoke-PMUNativeLeaseProbe {
    param(
        [object]$Operation,
        [string]$Root
    )

    $parent = Invoke-PMUNativeLeaseApprover
    $worker = $null
    try {
        $context = [pscustomobject]@{
            ModulePath = Initialize-PMUNativeLeaseModule $Root
            Operation = $Operation
            ParentPid = $parent.Id
            ParentStarted = Get-RepositoryProcessStart $parent.Id
            Token = Get-NativeJournalToken $Operation
        }
        $worker = [Diagnostics.Process]::Start((Initialize-NativeWorkerStartInfo $context))
        $serialized = [Management.Automation.PSSerializer]::Serialize($context, 30)
        $worker.StandardInput.WriteLine([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serialized)))
        [pscustomobject]@{ Parent = $parent; Worker = $worker; Error = $worker.StandardError.ReadToEndAsync() }
    } catch {
        Close-PMUChildProcess @(@($parent, $worker) | Where-Object { $_ })
        throw
    }
}

function Receive-PMUNativeLeaseMessage {
    param([object]$Probe)

    $message = $Probe.Worker.StandardOutput.ReadLineAsync()
    if (-not $message.Wait(15000)) {
        throw 'Disposable native worker did not produce its next protocol message.'
    }
    if (-not $message.Result) {
        throw "Disposable native worker closed its protocol: $($Probe.Error.GetAwaiter().GetResult())"
    }
    Read-NativeWorkerMessage ([IO.StringReader]::new($message.Result))
}
