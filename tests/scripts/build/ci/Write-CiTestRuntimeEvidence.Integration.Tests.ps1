# Cross-cutting CI evidence: the same helper must run inside Nova's integration runspace.
BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Write-CiTestRuntimeEvidence.ps1')
}

Describe 'CI integration execution runtime witness' -Tag 'BuildTooling' {
    It 'records the actual Nova build-validation runspace runtime when a lane requests evidence' {
        $PSVersionTable.PSEdition | Should -Be 'Core'
        Write-CiTestRuntimeEvidence
    }
}
