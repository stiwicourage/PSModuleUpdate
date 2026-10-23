BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Write-CiTestRuntimeEvidence.ps1')
}

Describe 'CI unit execution runtime witness' -Tag 'BuildTooling' {
    It 'records the actual Nova test runspace runtime when a lane requests evidence' {
        $PSVersionTable.PSEdition | Should -Be 'Core'
        Write-CiTestRuntimeEvidence
    }

    Context 'Owned evidence output' {
        BeforeEach {
            $script:savedPath = $env:PMU_CI_TEST_RUNTIME_PATH
            $script:savedContext = $env:PMU_CI_RUNTIME_CONTEXT
            $actual = Get-CiRuntimeRecord
            $context = @{
                Expected = @{ OperatingSystem = $actual.Environment.OperatingSystem; Architecture = $actual.Environment.ProcessArchitecture; PowerShellVersion = $actual.Environment.PowerShellVersion; PowerShellChannel = 'stable'; Executable = $actual.Executable }
                Identity = @{ phase = 'unit'; laneId = 'fixture' }
            }
            $env:PMU_CI_TEST_RUNTIME_PATH = Join-Path $TestDrive 'witness.json'
            $env:PMU_CI_RUNTIME_CONTEXT = Join-Path $TestDrive 'context.json'
            $context | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $env:PMU_CI_RUNTIME_CONTEXT
        }
        AfterEach {
            $env:PMU_CI_TEST_RUNTIME_PATH = $script:savedPath
            $env:PMU_CI_RUNTIME_CONTEXT = $script:savedContext
        }
        It 'records the Pester version actually executing the tests, not the newest available installation' {
            Write-CiTestRuntimeEvidence
            $record = Get-Content -LiteralPath $env:PMU_CI_TEST_RUNTIME_PATH -Raw | ConvertFrom-Json
            $record.PesterVersion | Should -Be (Get-Module Pester).Version.ToString()
            $record.ProcessId | Should -Be $PID
            $record.Executable | Should -Be (Get-Process -Id $PID).Path
        }
    }
}
