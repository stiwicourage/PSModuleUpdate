BeforeAll {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $root 'scripts/build/ci/Invoke-PlatformLane.ps1')
}

Describe 'Invoke-CiLanePhase' -Tag 'BuildTooling' {
    It 'runs the command in a fresh PowerShell process and records a zero exit code' {
        $log = Join-Path $TestDrive 'ok.log'

        $request = @{
            Name = 'ok'
            Command = 'Write-Output ''hello from child'''
            LogPath = $log
            WorkingDirectory = $TestDrive
        }
        $phase = Invoke-CiLanePhase -Phase $request

        $phase.Name | Should -Be 'ok'
        $phase.ExitCode | Should -Be 0
        $phase.Environment.PowerShellVersion | Should -Be $PSVersionTable.PSVersion.ToString()
        $phase.Environment.PowerShellEdition | Should -Be 'Core'
        $phase.Environment.ProcessArchitecture | Should -Be ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString())
        $phase.Executable | Should -Be (Get-Process -Id $PID).Path
        Get-Content -LiteralPath $log -Raw | Should -Match 'hello from child'
    }

    It 'preserves a nonzero exit code so test failures fail the lane' {
        $log = Join-Path $TestDrive 'fail.log'

        $request = @{
            Name = 'fail'
            Command = 'Write-Output ''boom''; exit 3'
            LogPath = $log
            WorkingDirectory = $TestDrive
        }
        $phase = Invoke-CiLanePhase -Phase $request

        $phase.ExitCode | Should -Be 3
        Get-Content -LiteralPath $log -Raw | Should -Match 'boom'
    }

    It 'treats a terminating error as a failed phase' {
        $log = Join-Path $TestDrive 'throw.log'

        $request = @{
            Name = 'throw'
            Command = 'throw ''bad'''
            LogPath = $log
            WorkingDirectory = $TestDrive
        }
        $phase = Invoke-CiLanePhase -Phase $request

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

Describe 'Get-CiModuleVersion' -Tag 'BuildTooling', 'CiModuleInventory' {
    BeforeEach {
        Mock Get-Module {
            [pscustomobject]@{ Version = [version]'1.0.0' }
        }
    }

    It 'reports the qualified provider even when the runtime bundles a newer version' {
        Mock Get-Module {
            [pscustomobject]@{ Version = [version]'1.3.1' }
            [pscustomobject]@{ Version = [version]'1.2.0' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' }
        $modules = Get-CiModuleVersion
        $modules['Microsoft.PowerShell.PSResourceGet'] | Should -BeExactly @('1.2.0')
        $modules.Pester | Should -BeExactly @('1.0.0')
    }

    It 'does not report an unqualified provider as available when the required version is absent' {
        Mock Get-Module {
            [pscustomobject]@{ Version = [version]'1.3.1' }
        } -ParameterFilter { $Name -eq 'Microsoft.PowerShell.PSResourceGet' }
        $modules = Get-CiModuleVersion
        $modules['Microsoft.PowerShell.PSResourceGet'].Count | Should -Be 0
    }
}
