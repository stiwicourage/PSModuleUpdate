function Initialize-QualificationProcessInfo {
    param(
        [hashtable]$Options,
        [string]$Root,
        [pscredential]$Credential
    )

    $info = [Diagnostics.ProcessStartInfo]::new((Join-Path $PSHOME 'pwsh'))
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', "$PSScriptRoot/Invoke-QualificationChild.ps1")) {
        $info.ArgumentList.Add($argument)
    }
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    Initialize-QualificationChildEnvironment $info $Options $Root
    if ($Credential) {
        Initialize-QualificationChildCredential $info $Credential
    }
    $info
}

function Initialize-QualificationChildEnvironment {
    param(
        [Diagnostics.ProcessStartInfo]$Info,
        [hashtable]$Options,
        [string]$Root
    )

    $Info.Environment['HOME'] = "$Root/home"
    $Info.Environment['XDG_DATA_HOME'] = "$Root/home/.local/share"
    $Info.Environment['XDG_CONFIG_HOME'] = "$Root/home/.config"
    $Info.Environment['XDG_CACHE_HOME'] = "$Root/home/.cache"
    $Info.Environment['PMU_QUALIFICATION_OPTIONS'] = ConvertTo-Json $Options -Compress
    $Info.Environment['PMU_QUALIFICATION_ROOT'] = $Root
    $Info.Environment['PSModulePath'] = $env:PSModulePath
}

function Initialize-QualificationChildCredential {
    param(
        [Diagnostics.ProcessStartInfo]$Info,
        [pscredential]$Credential
    )

    $Info.Environment['PMU_QUALIFICATION_USERNAME'] = $Credential.UserName
    $Info.Environment['PMU_QUALIFICATION_PASSWORD'] = $Credential.GetNetworkCredential().Password
}

function Invoke-QualificationChild {
    param(
        [hashtable]$Options,
        [string]$Root,
        [pscredential]$Credential
    )

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = Initialize-QualificationProcessInfo $Options $Root $Credential
    try {
        [void]$process.Start()
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()
        Wait-QualificationChild $process
        [void]$errorTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) {
            throw 'Qualification child failed; raw provider errors withheld.'
        }
        $text = $outputTask.GetAwaiter().GetResult()
        [regex]::Match($text, '(?m)^\{.+\}\s*$').Value | ConvertFrom-Json -Depth 30
    } finally {
        $process.Dispose()
    }
}

function Wait-QualificationChild {
    param([Diagnostics.Process]$Process)
    if ($Process.WaitForExit(300000)) {
        return
    }
    $Process.Kill($true)
    $Process.WaitForExit()
    throw 'Qualification exceeded five minutes; shared-store cleanup must be checked explicitly.'
}
function Initialize-QualificationLaunchOption {
    param([hashtable]$Options)
    $Options.ModulePath = (Resolve-Path -LiteralPath $Options.ModulePath).Path
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $moduleScript = [IO.Path]::ChangeExtension($Options.ModulePath, '.psm1')
    if ($Options['ApprovedBuildSha256']) {
        Assert-QualificationModuleHash $moduleScript $Options['ApprovedBuildSha256']
    } else {
        Assert-QualificationBuild $moduleScript "$projectRoot/src"
    }
    if ($Options['RepositoryUri']) {
        Assert-QualificationEndpoint $Options['RepositoryUri']
    }
}

function Get-QualificationTemporaryRoot {
    Push-Location ([IO.Path]::GetTempPath())
    try {
        $physicalBase = & /bin/pwd -P
        Assert-QualificationUnlinkedPath $physicalBase
        Join-Path $physicalBase "pmu-qualification-$([guid]::NewGuid().ToString('N'))"
    } finally {
        Pop-Location
    }
}
