BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Invoke-PlatformLane.ps1')
}

Describe 'Invoke-CiLanePhase' -Tag 'BuildTooling' {
    It 'runs the command in a fresh PowerShell process and records a zero exit code' {
        $log = Join-Path $TestDrive 'ok.log'

        $phase = Invoke-CiLanePhase -Name 'ok' -Command 'Write-Output ''hello from child''' -LogPath $log -WorkingDirectory $TestDrive

        $phase.Name | Should -Be 'ok'
        $phase.ExitCode | Should -Be 0
        Get-Content -LiteralPath $log -Raw | Should -Match 'hello from child'
    }

    It 'preserves a nonzero exit code so test failures fail the lane' {
        $log = Join-Path $TestDrive 'fail.log'

        $phase = Invoke-CiLanePhase -Name 'fail' -Command 'Write-Output ''boom''; exit 3' -LogPath $log -WorkingDirectory $TestDrive

        $phase.ExitCode | Should -Be 3
        Get-Content -LiteralPath $log -Raw | Should -Match 'boom'
    }

    It 'treats a terminating error as a failed phase' {
        $log = Join-Path $TestDrive 'throw.log'

        $phase = Invoke-CiLanePhase -Name 'throw' -Command 'throw ''bad''' -LogPath $log -WorkingDirectory $TestDrive

        $phase.ExitCode | Should -Not -Be 0
    }
}

Describe 'Get-CiLaneDefinition' -Tag 'BuildTooling' {
    It 'returns the lane with the requested identifier' {
        $lane = Get-CiLaneDefinition -LaneId 'linux-x64-ps74'
        $lane.os | Should -Be 'Linux'
        $lane.powershell | Should -Be '7.4'
    }

    It 'fails for an unknown lane so a typo cannot silently run nothing' {
        { Get-CiLaneDefinition -LaneId 'nope' } | Should -Throw '*Unknown lane*'
    }
}
