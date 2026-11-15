BeforeAll { . "$PSScriptRoot/../../TestHelpers/Import-PMUTestSource.ps1" }
Describe 'Get-LinuxClockTickFrequency' -Tag 'PMUUriBridge' {
    Context 'Clock command protocol' {
        BeforeEach {
            $previousExitCode = Get-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
            $script:clockExitState = @{
                Present = [bool]$previousExitCode
                Value = if ($previousExitCode) { $previousExitCode.Value } else { $null }
            }
        }
        AfterEach {
            if ($script:clockExitState.Present) {
                Set-Variable LASTEXITCODE $script:clockExitState.Value -Scope Global
            } else {
                Remove-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
            }
        }
        It 'returns the clock command output only after a successful exit' {
            $command = Join-Path $TestDrive 'clock-success.ps1'
            [IO.File]::WriteAllText($command, "param([string]`$Name); if (`$Name -ne 'CLK_TCK') { exit 2 }; '100'; exit 0")
            Get-LinuxClockTickFrequency $command | Should -BeExactly '100'
        }
        It 'rejects a failed clock command instead of using its plausible numeric output' {
            $command = Join-Path $TestDrive 'clock-failure.ps1'
            [IO.File]::WriteAllText($command, "'100'; exit 2")
            { Get-LinuxClockTickFrequency $command } |
                Should -Throw -ExceptionType ([IO.InvalidDataException]) -ExpectedMessage 'Cannot read the Linux process clock frequency.'
        }
    }
}
