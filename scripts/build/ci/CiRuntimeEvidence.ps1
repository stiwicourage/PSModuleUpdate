. (Join-Path $PSScriptRoot 'CiLaneEnvironment.ps1')

function Get-CiRuntimeRecord {
    return @{
        Executable = (Get-Process -Id $PID).Path
        ProcessId = $PID
        Environment = Get-CiLaneEnvironment
    }
}

function Assert-CiRuntimeRecord {
    param(
        [Parameter(Mandatory)]$Record,
        [Parameter(Mandatory)]$Expected
    )

    $mismatch = @(Test-CiLaneEnvironment -Expected $Expected -Actual $Record.Environment)
    if ($Record.Executable -ne $Expected.Executable) {
        $mismatch += 'PowerShell executable differs from the selected absolute path.'
    }
    if ($mismatch.Count -gt 0) {
        throw ($mismatch -join ' ')
    }
}

function Read-CiRuntimeProbe {
    param([Parameter(Mandatory)][string]$Executable)

    if (-not [IO.Path]::IsPathRooted($Executable)) {
        throw 'PowerShell executable must be an absolute path.'
    }
    $output = & $Executable -NoLogo -NoProfile -File $PSCommandPath
    if ($LASTEXITCODE -ne 0) {
        throw 'PowerShell runtime probe failed.'
    }
    return $output | ConvertFrom-Json
}

function Assert-CiRuntimeIdentity {
    param(
        [Parameter(Mandatory)]$Record,
        [Parameter(Mandatory)]$Identity,
        [Parameter(Mandatory)][string]$Phase
    )

    foreach ($name in 'laneId', 'commitSha', 'runId', 'runAttempt', 'executionId') {
        if ($Record.Context.$name -cne $Identity.$name) {
            throw "Runtime evidence identity differs at '$name'."
        }
    }
    if ($Record.Context.phase -cne $Phase) {
        throw 'Runtime evidence belongs to another phase.'
    }
    if ($Record.ProcessId -le 0) {
        throw 'Runtime evidence has no actual process identity.'
    }
}

function Assert-CiPhaseRuntimeEvidence {
    param(
        [Parameter(Mandatory)]$Phase,
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)]$Identity,
        [Parameter(Mandatory)][string]$Directory
    )

    Assert-CiRuntimeRecord -Record $Phase -Expected $Expected
    $path = Join-Path $Directory "$($Phase.Name).log.runtime.json"
    $record = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
    Assert-CiRuntimeRecord -Record $record -Expected $Expected
    Assert-CiRuntimeIdentity -Record $record -Identity $Identity -Phase $Phase.Name
    if ($record.ProcessId -ne $Phase.ProcessId) {
        throw 'Phase runtime process identity differs.'
    }
    if ($Phase.Name -eq 'build') {
        return
    }
    $witness = Get-Content -LiteralPath (Join-Path $Directory "$($Phase.Name).log.test-runtime.json") -Raw -ErrorAction Stop | ConvertFrom-Json
    Assert-CiRuntimeRecord -Record $witness -Expected $Expected
    Assert-CiRuntimeIdentity -Record $witness -Identity $Identity -Phase $Phase.Name
    if ($witness.ProcessId -ne $record.ProcessId) {
        throw 'Nova test runtime is not the validated phase runtime.'
    }
    if ($witness.PesterVersion -cne '5.7.1') {
        throw 'Nova tests did not execute with the pinned Pester version.'
    }
}

function Assert-CiLaneRuntimeEvidence {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Phase,
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)]$Identity
    )

    if ($Phase.Count -ne 3) {
        throw 'Exactly three completed phase records are required.'
    }
    foreach ($name in 'build', 'unit', 'integration') {
        $own = @($Phase | Where-Object Name -eq $name)
        if ($own.Count -ne 1) {
            throw "Missing or duplicate phase '$name'."
        }
        if ($own[0].ExitCode -ne 0) {
            throw "Phase '$name' failed."
        }
        Assert-CiPhaseRuntimeEvidence -Phase $own[0] -Expected $Expected -Identity $Identity -Directory $Directory
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-CiRuntimeRecord | ConvertTo-Json -Depth 4 -Compress
}
