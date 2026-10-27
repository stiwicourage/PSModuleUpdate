BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/CiLaneManifest.ps1')

    function Build-PhaseList {
        param(
            [int]$Build = 0,
            [int]$Unit = 0,
            [int]$Integration = 0
        )

        @(
            [pscustomobject]@{
                Name = 'build'
                ExitCode = $Build
            }
            [pscustomobject]@{
                Name = 'unit'
                ExitCode = $Unit
            }
            [pscustomobject]@{
                Name = 'integration'
                ExitCode = $Integration
            }
        )
    }

    function Build-SummaryMap {
        param(
            [int]$UnitTotal = 10,
            [int]$UnitFailed = 0,
            [int]$IntegrationFailed = 0
        )

        @{
            unit = [pscustomobject]@{
                Total = $UnitTotal
                Passed = $UnitTotal - $UnitFailed
                Failed = $UnitFailed
                Skipped = 0
                SkippedName = @()
            }
            integration = [pscustomobject]@{
                Total = 2
                Passed = 2 - $IntegrationFailed
                Failed = $IntegrationFailed
                Skipped = 0
                SkippedName = @()
            }
        }
    }
}

Describe 'Get-CiLaneStatus' -Tag 'BuildTooling' {
    It 'passes only when every phase succeeded and tests were actually executed' {
        Get-CiLaneStatus -Mismatch @() -Phase (Build-PhaseList) -Summary (Build-SummaryMap) | Should -Be 'passed'
    }

    It 'fails when the environment does not match the lane' {
        Get-CiLaneStatus -Mismatch @('Operating system is wrong') -Phase (Build-PhaseList) -Summary (Build-SummaryMap) | Should -Be 'failed'
    }

    It 'fails when a phase exits nonzero' {
        Get-CiLaneStatus -Mismatch @() -Phase (Build-PhaseList -Integration 1) -Summary (Build-SummaryMap) | Should -Be 'failed'
    }

    It 'fails when a required phase did not run' {
        $phases = @(Build-PhaseList | Where-Object Name -ne 'integration')
        Get-CiLaneStatus -Mismatch @() -Phase $phases -Summary (Build-SummaryMap) | Should -Be 'failed'
    }

    It 'fails when the unit test run executed no tests' {
        Get-CiLaneStatus -Mismatch @() -Phase (Build-PhaseList) -Summary (Build-SummaryMap -UnitTotal 0) | Should -Be 'failed'
    }

    It 'fails when the report records failures even though the exit codes were zero' {
        Get-CiLaneStatus -Mismatch @() -Phase (Build-PhaseList) -Summary (Build-SummaryMap -UnitFailed 1) | Should -Be 'failed'
    }

    It 'fails when a summary is missing' {
        Get-CiLaneStatus -Mismatch @() -Phase (Build-PhaseList) -Summary @{ unit = (Build-SummaryMap).unit } | Should -Be 'failed'
    }

    It 'fails when integration executed no tests despite successful phase exit' {
        $summary = Build-SummaryMap
        $summary.integration.Total = $summary.integration.Passed = 0
        Get-CiLaneStatus -Phase (Build-PhaseList) -Summary $summary | Should -Be 'failed'
    }

    It 'fails when all unit tests were skipped rather than executed' {
        $summary = Build-SummaryMap
        $summary.unit.Passed = 0
        $summary.unit.Skipped = 10
        Get-CiLaneStatus -Phase (Build-PhaseList) -Summary $summary | Should -Be 'failed'
    }
}

Describe 'Build-CiLaneManifest' -Tag 'BuildTooling' {
    It 'records identity, status, phases, test counts and modules for the gate to verify' {
        $environment = [pscustomobject]@{
            OperatingSystem = 'Linux'
            PowerShellVersion = '7.4.21'
        }
        $manifest = Build-CiLaneManifest -LaneId 'linux-x64-ps74' -CommitSha 'abc123' -Environment $environment -Mismatch @() `
            -Phase (Build-PhaseList) -Summary (Build-SummaryMap) -Module @{ Pester = '5.7.1' }

        $manifest.laneId | Should -Be 'linux-x64-ps74'
        $manifest.commitSha | Should -Be 'abc123'
        $manifest.status | Should -Be 'passed'
        $manifest.environment.PowerShellVersion | Should -Be '7.4.21'
        @($manifest.phases).Count | Should -Be 3
        $manifest.tests.unit.Total | Should -Be 10
        $manifest.modules.Pester | Should -Be '5.7.1'
    }

    It 'survives a JSON round trip with the status intact' {
        $manifest = Build-CiLaneManifest -LaneId 'x' -CommitSha 'y' -Environment ([pscustomobject]@{}) -Mismatch @('bad') `
            -Phase (Build-PhaseList) -Summary (Build-SummaryMap) -Module @{}

        ($manifest | ConvertTo-Json -Depth 6 | ConvertFrom-Json).status | Should -Be 'failed'
    }
}
