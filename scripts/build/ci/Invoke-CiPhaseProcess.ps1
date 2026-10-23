[CmdletBinding()]
param([Parameter(Mandatory)][string]$ContextFile)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'CiRuntimeEvidence.ps1')

function Write-CiPhaseRuntime {
    param([Parameter(Mandatory)]$Context)

    $record = Get-CiRuntimeRecord
    Assert-CiRuntimeRecord -Record $record -Expected $Context.Expected
    $record.Context = $Context.Identity
    $record.ModulePath = $env:PSModulePath
    $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Context.RuntimePath
}

function Invoke-CiPhaseProcess {
    param([Parameter(Mandatory)][string]$ContextFile)

    $context = Get-Content -LiteralPath $ContextFile -Raw | ConvertFrom-Json
    Push-Location -LiteralPath $context.WorkingDirectory
    try {
        Write-CiPhaseRuntime -Context $context
        $env:PMU_CI_TEST_RUNTIME_PATH = $context.TestRuntimePath
        $env:PMU_CI_RUNTIME_CONTEXT = $ContextFile
        & ([scriptblock]::Create($context.Command))
    } finally {
        Pop-Location
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-CiPhaseProcess -ContextFile $ContextFile
}
