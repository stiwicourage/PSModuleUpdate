. (Join-Path $PSScriptRoot 'CiRuntimeEvidence.ps1')

function Write-CiTestRuntimeEvidence {
    if (-not $env:PMU_CI_TEST_RUNTIME_PATH) {
        return
    }
    $context = Get-Content -LiteralPath $env:PMU_CI_RUNTIME_CONTEXT -Raw -ErrorAction Stop | ConvertFrom-Json
    $record = Get-CiRuntimeRecord
    Assert-CiRuntimeRecord -Record $record -Expected $context.Expected
    $record.Context = $context.Identity
    $record.PesterVersion = (Get-Module Pester -ErrorAction Stop).Version.ToString()
    $record.ModulePath = $env:PSModulePath
    $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $env:PMU_CI_TEST_RUNTIME_PATH -ErrorAction Stop
}
